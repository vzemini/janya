# encoding: utf-8
#
# Janya Server - Compliance, Process Management Software
# Copyright (C) 2016- 2020 Janya Inc, Venkat Allu, PMP®

module BoardsHelper
  def board_breadcrumb(item)
    board = item.is_a?(Message) ? item.board : item
    links = [link_to(l(:label_board_plural), project_boards_path(item.project))]
    boards = board.ancestors.reverse
    if item.is_a?(Message)
      boards << board
    end
    links += boards.map {|ancestor| link_to(h(ancestor.name), project_board_path(ancestor.project, ancestor))}
    breadcrumb links
  end

  def boards_options_for_select(boards)
    options = []
    Board.board_tree(boards) do |board, level|
      label = (level > 0 ? '&nbsp;' * 2 * level + '&#187; ' : '').html_safe
      label << board.name
      options << [label, board.id]
    end
    options
  end
end
