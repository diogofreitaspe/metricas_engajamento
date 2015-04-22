require 'csv'

$ignored_users = ['-', 'CABELTRAM', 'MateusNoronha', 'deborahcalacia', 'arianeprado', 'TahZanin', 'viniciuscarvalho', 'BrunaMM', 'Alcruz', 'MarRib', 'diogosfreitas', 'ariprado']

def read_csv(url)
  csv = CSV.read(url)
  data = Array.new

  csv.drop(1).each_with_index do |row, row_index|
    data[row_index] = Hash.new
    csv[0].each_with_index do |header, col_index|
      data[row_index][header] = row[col_index]
    end
  end
  data
end

def is_valid_user(user_id)
  not $ignored_users.include?(user_id)
end
