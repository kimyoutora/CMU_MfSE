module TeamsHelper

  def twiki_user_link(twiki_username, human_name)
    "<a href='http://rails.sv.cmu.edu/people/#{twiki_username}' target='_top'>#{human_name}</a>".html_safe
  end

  def find_past_teams(person)
    @past_teams_as_member = Team.find_by_sql(["SELECT t.* FROM  teams t OUTER JOIN teams_people tp ON ( t.id = tp.team_id) OUTER JOIN users u ON (tp.person_id = u.id) OUTER JOIN courses c ON (t.course_id = c.id) WHERE u.id = ? AND (c.semester <> ? OR c.year <> ?)", person.id, AcademicCalendar.current_semester(), Date.today.year])

    teams_list = ""
    count = 0
    @past_teams_as_member.each do |team|
      if count == 0
        teams_list = team.name
      else
        teams_list = teams_list.concat(", " + team.name)
      end
      count -= 1
    end
  end

end
