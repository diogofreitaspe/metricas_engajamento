require 'csv'
require 'set'

$ignored_users = ['CABELTRAM', 'MateusNoronha', 'deborahcalacia', 'arianeprado', 'TahZanin', 'viniciuscarvalho', 'BrunaMM', 'Alcruz', 'MarRib']
$all_profs = Set.new

$min_created_contents = 3
$min_logins = 2
$min_access_in_content = 10
$min_access_in_content = 3
$min_accessed_contents = 3


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

#CONTAGEM DE PROFESSORES ATIVOS

def count_active_profs
  active_users = read_csv("CSV/Pessoas_Ativas.csv")

  prof_ativos = Hash.new

  active_users.each do |row|
    namespace = row['namespace']
    prof_ativos[namespace] ||= Set.new
    prof = row['user_id']
    if row['teacher'] == '1' and not $ignored_users.include?(prof)
      prof_ativos[namespace].add(prof) 
      $all_profs.add(prof)
    end
  end

  n_prof_ativos = Hash.new

  prof_ativos.each do |ns, profs|
    n_prof_ativos[ns] = profs.size
  end
  n_prof_ativos
end

#CONTAGEM DE PROFESSORES QUE LOGARAM MAIS DE UMA VEZ
def count_logged_profs
  users_access = read_csv("CSV/Pessoas_Acessaram.csv")

  prof_logaram = Hash.new

  users_access.each do |row|
    namespace = row['namespace']
    prof_logaram[namespace] ||= Hash.new
    prof = row['user_id']
    if row['teacher'] == '1' and is_valid_user(prof)
      prof_logaram[namespace][prof] ||= 0
      prof_logaram[namespace][prof] += 1
    end
  end

  n_prof_logaram = Hash.new

  prof_logaram.each do |ns, profs|
    n_prof_logaram[ns] ||= 0
    profs.each do |prof, n_logins|
      n_prof_logaram[ns] += 1 if n_logins >= $min_logins
    end
  end
  n_prof_logaram
end

#CONTAGEM DE PROFESSORES QUE PRODUZEM MATERIAIS
def count_producer_profs
  created_content = read_csv("CSV/Conteudos_Criados.csv")

  prof_produtores = Hash.new

  created_content.each do |row|
    namespace = row['namespace']
    prof_produtores[namespace] ||= Hash.new
    prof = row['teacher_id']
    if row['type'] != 'EXERCISE' and row['type'] != '-' and is_valid_user(prof)
      prof_produtores[namespace][prof] ||= 0
      prof_produtores[namespace][prof] += 1
    end
  end

  n_prof_produtores = Hash.new

  prof_produtores.each do |ns, profs|
    n_prof_produtores[ns] ||= 0
    profs.each do |prof, n_created_content|
      n_prof_produtores[ns] += 1 if n_created_content >= $min_created_contents
    end
  end
  n_prof_produtores
end


#CONTAGEM DE PROFESSORES QUE USARAM MATERIAIS COM SEUS ALUNOS
def count_teaching_profs
  accessed_content = read_csv("CSV/Conteudos_Acessados.csv")

  prof_ensinaram = Hash.new

  accessed_content.each do |row|
    namespace = row['namespace']
    prof_ensinaram[namespace] ||= Hash.new
    prof = row['teacher_id']
    if row['type'] != 'EXERCISE' and row['type'] != '-' and is_valid_user(prof)
      content = row['title']
      prof_ensinaram[namespace][prof] ||= Hash.new
      prof_ensinaram[namespace][prof][content] ||= 0
      prof_ensinaram[namespace][prof][content] += row['users access'].to_i
    end
  end

  n_prof_ensinaram = Hash.new

  prof_ensinaram.each do |ns, profs|
    n_prof_ensinaram[ns] ||= 0
    profs.each do |prof, contents|
      n_accessed_contents = 0
      contents.each do |content, n_access|
        n_accessed_contents += 1 if n_access >= $min_access_in_content
      end
      n_prof_ensinaram[ns] += 1 if n_accessed_contents >= $min_accessed_contents
    end
  end
  n_prof_ensinaram
end

def is_valid_user(user_id)
  $all_profs.include?(user_id)
end


active = count_active_profs
producer = count_producer_profs
logged = count_logged_profs
teaching = count_teaching_profs

CSV.open("rela.csv", "wb") do |csv|
  csv << ["namespace", "profs_ativos", "profs_logaram", "profs_criaram", "profs_ensinaram"]
  active.each do |ns, value|
    csv << [ns, active[ns], logged[ns], producer[ns], teaching[ns]]
  end
end