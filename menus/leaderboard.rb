def open_leaderboard_screen
  page_size = 10
  page = 0

  loop do
    players = get_local_leaderboard(limit: nil)
    page_count = [(players.length.to_f / page_size).ceil, 1].max
    page = [[page, 0].max, page_count - 1].min

    clear
    draw_header("L O C A L  L E A D E R B O A R D")
    puts box_line(Color.dim("Lifetime points earned, grouped by username across saves"))
    puts

    if players.empty?
      puts box_line(Color.dim("No points have been recorded yet."))
    else
      players.slice(page * page_size, page_size).each_with_index do |player, index|
        rank = page * page_size + index + 1
        puts box_line("#{Color.bold(Color.yellow("##{rank}"))}  #{Color.bold(player['username'])}  —  #{Color.cyan("#{player['total_points']} pts")}")
      end
    end

    puts
    puts box_line("Page #{page + 1}/#{page_count}  [N] Next  [P] Previous  [X] Back")
    print "  Choice: "
    choice = $stdin.gets&.strip&.downcase

    case choice
    when 'n' then page = (page + 1) % page_count
    when 'p' then page = (page - 1) % page_count
    when 'x', nil then return
    end
  end
end