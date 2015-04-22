require 'set'
require 'Date'
load 'util.rb'

module Enumerable
  def sum
    self.inject(0){|accum, i| accum + i }
  end

  def average
    self.sum/self.length.to_f
  end

  def var
    m = self.average
    sum = self.inject(0){|accum, i| accum +(i-m)**2 }
    sum/(self.length - 1).to_f
  end

  def stddev
    return Math.sqrt(self.var)
  end
end 

def get_active_profs
  active_users = read_csv("CSV/Pessoas_Ativas.csv")

  prof_ativos = Hash.new

  active_users.each do |row|
    namespace = row['namespace']
    prof_ativos[namespace] ||= Set.new
    prof = row['user_id']
    if row['teacher'] == '1' and not $ignored_users.include?(prof)
      prof_ativos[namespace].add(prof) 
    end
  end
  prof_ativos
end

#Informações de login
def login_frequency_profs
  users_access = read_csv("CSV/Pessoas_Acessaram.csv")

  prof_logaram = Hash.new

  users_access.each do |row|
    namespace = row['namespace']
    prof_logaram[namespace] ||= Hash.new
    prof = row['user_id']
    if row['teacher'] == '1' and is_valid_user(prof)
      prof_logaram[namespace][prof] ||= Array.new
      prof_logaram[namespace][prof].push(Date.strptime(row['day'], "%Y-%m-%d"))
    end
  end
  
  prof_login_frequency = Hash.new

  prof_logaram.each do |ns, profs|
    prof_login_frequency[ns] ||= Hash.new
    profs.each do |prof, logins|
      i = 1
      periods = Array.new
      while i < logins.size do
        periods.push( (logins[i]-logins[i-1]).to_i )
        i += 1
      end
      prof_login_frequency[ns][prof] ||= Hash.new
      frequency = periods.average
      prof_login_frequency[ns][prof]['n_logins'] = logins.size
      prof_login_frequency[ns][prof]['frequency'] = frequency unless frequency.nan?
    end
  end
  prof_login_frequency
end

#Informações de criação de conteúdo
def producer_frequency_profs
  created_content = read_csv("CSV/Conteudos_Criados.csv")

  prof_produtores = Hash.new

  created_content.each do |row|
    namespace = row['namespace']
    prof_produtores[namespace] ||= Hash.new
    prof = row['teacher_id']
    if row['type'] != 'EXERCISE' and row['type'] != '-' and is_valid_user(prof)
      prof_produtores[namespace][prof] ||= Array.new
      prof_produtores[namespace][prof].push(Date.strptime(row['day'], "%Y-%m-%d"))
    end
  end

  prof_producer_frequency = Hash.new

  prof_produtores.each do |ns, profs|
    prof_producer_frequency[ns] ||= Hash.new
    profs.each do |prof, creations|
      i = 1
      periods = Array.new
      while i < creations.size
        period = (creations[i]-creations[i-1]).to_i
        periods.push(period) unless period == 0
        i += 1
      end
      prof_producer_frequency[ns][prof] ||= Hash.new
      frequency = periods.average
      prof_producer_frequency[ns][prof]['n_contents'] = creations.size
      prof_producer_frequency[ns][prof]['frequency'] = frequency unless frequency.nan?
    end
  end
  prof_producer_frequency
end

#CONTAGEM DE PROFESSORES QUE USARAM MATERIAIS COM SEUS ALUNOS
def count_teaching_profs
  $min_access_in_content = 3
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

  content_access = Hash.new

  prof_ensinaram.each do |ns, profs|
    content_access[ns] ||= Hash.new
    profs.each do |prof, contents|
      content_access[ns][prof] ||= 0
      contents.each do |content, n_access|
        content_access[ns][prof] += 1 if n_access >= $min_access_in_content
      end
    end
  end
  content_access
end

active_profs = get_active_profs
logins = login_frequency_profs
productions = producer_frequency_profs
access = count_teaching_profs

CSV.open("frequency.csv", "wb") do |csv|
  csv << ["namespace", "prof", "n_login", "f_login", "n_content", 'f_content', 'n_access']
  active_profs.each do |ns, profs|
    profs.each do |prof|
      n_login = logins[ns][prof].nil? ? "" : logins[ns][prof]['n_logins']
      f_login = logins[ns][prof].nil? ? "" : logins[ns][prof]['frequency']
      n_content = productions[ns][prof].nil? ? "" : productions[ns][prof]['n_contents']
      f_content = productions[ns][prof].nil? ? "" : productions[ns][prof]['frequency']
      n_access = access[ns][prof].nil? ? "" : access[ns][prof]
      csv << [ns, prof, n_login, f_login, n_content, f_content, n_access]
    end
  end
end