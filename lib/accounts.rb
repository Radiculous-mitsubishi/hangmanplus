require 'openssl'
require 'securerandom'
require_relative 'save_system'

ACCOUNTS_PATH = File.join(SAVES_DIR, 'accounts.json')
ACCOUNT_PASSWORD_ITERATIONS = 210_000

def read_local_accounts
  ensure_saves_dir
  return { 'accounts' => [] } unless File.exist?(ACCOUNTS_PATH)

  data = JSON.parse(File.read(ACCOUNTS_PATH))
  data['accounts'].is_a?(Array) ? data : { 'accounts' => [] }
end

def create_local_account(username, password)
  clean_username = username.to_s.strip
  unless clean_username.match?(/\A[a-zA-Z0-9_]{3,20}\z/)
    return [false, 'Username must be 3–20 characters: letters, numbers, or underscores.']
  end
  return [false, 'The username Player is reserved for older, unassigned saves.'] if clean_username.casecmp?('Player')
  return [false, 'Password must be at least 8 characters.'] if password.to_s.length < 8

  data = read_local_accounts
  duplicate = data['accounts'].any? do |account|
    account['username'].to_s.casecmp?(clean_username)
  end
  return [false, 'That username is already registered on this device.'] if duplicate

  salt = SecureRandom.hex(16)
  digest = derive_account_password(password, salt)
  data['accounts'] << {
    'username' => clean_username,
    'salt' => salt,
    'password_hash' => digest,
    'created_at' => Time.now.to_s
  }
  File.write(ACCOUNTS_PATH, JSON.pretty_generate(data))
  [true, clean_username]
rescue => error
  [false, "Could not create the local account: #{error.message}"]
end

def authenticate_local_account(username, password)
  data = read_local_accounts
  account = data['accounts'].find do |entry|
    entry['username'].to_s.casecmp?(username.to_s.strip)
  end
  return nil unless account

  actual = derive_account_password(password.to_s, account['salt'].to_s)
  expected = account['password_hash'].to_s
  return nil unless actual.bytesize == expected.bytesize
  return nil unless OpenSSL.fixed_length_secure_compare(actual, expected)

  account['username']
rescue
  nil
end

def derive_account_password(password, salt)
  OpenSSL::KDF.pbkdf2_hmac(
    password,
    salt: salt,
    iterations: ACCOUNT_PASSWORD_ITERATIONS,
    length: 32,
    hash: 'sha256'
  ).unpack1('H*')
end