# ── Colour helpers ──────────────────────────────────────────
module Color
  def self.red(s)     "\e[31m#{s}\e[0m" end
  def self.green(s)   "\e[32m#{s}\e[0m" end
  def self.yellow(s)  "\e[33m#{s}\e[0m" end
  def self.cyan(s)    "\e[36m#{s}\e[0m" end
  def self.bold(s)    "\e[1m#{s}\e[0m"  end
  def self.dim(s)     "\e[2m#{s}\e[0m"  end
  def self.magenta(s) "\e[35m#{s}\e[0m" end
  def self.white(s)   "\e[97m#{s}\e[0m" end
  def self.rarity(r)
    case r
    when :common then "\e[37m#{r}\e[0m"
    when :rare then cyan(r.to_s)
    when :ultra_rare then magenta(r.to_s)
    when :legendary then yellow(r.to_s)
    when :mythic then "\e[35m#{r}\e[0m"
    else r.to_s
    end
  end
end
