# this task cleans up spammy users
# in order to not overwhelm the database, it iterates backwards through time, one week at a time
# an inactive user is defined as a user who has no user_participations and no groups
# it will destroy users if:
#   * they match the pattern of spammy users found in june 2012
#   * a user is inactive and was last seen more than a year ago
#
# examples:
#  rake cg:cleanup_spammy_users
#   => will iterate backwards through every week until there are no more users
#
#  rake cg:cleanup_spammy_users quit_when_no_active_users=1
#   => will stop iterating when it finds a week when there are no inactive users
#
#  rake cg:cleanup_spammy_users only_spammers=1
#   => will stop iterating when it finds a week when there were no spammers created

namespace :cg do
  task :cleanup_spammy_users => :environment do
    $stdout.puts "Cleaning up spammy users."
    week_num = 0
    oldest_user_created_at = User.find(1).created_at.to_i
    only_inactive = ENV['quit_when_no_inactive_users'] || ENV['only_spammers']
    users = get_users(week_num, only_inactive)
    while do_loop(users, oldest_user_created_at, week_num, only_inactive) 
      $stdout.puts "Looking at week #{week_num.to_s}"
      june_2012_spammers = 0
      inactive_users = 0
      users_count = users.count
      users.each_with_index do |user, i|
        inactive_user = only_inactive ? true : user_is_inactive?(user)
        if inactive_user
          if user_is_spammer?(user) 
            june_2012_spammers += 1
            $stdout.puts "[#{i.to_s}/#{users_count.to_s}] Removing user #{user.login}, #{user.email}"
            user.destroy
            sleep 1
          elsif user_has_not_logged_in(user) 
            inactive_users += 1
          end
        end
      end
      $stdout.puts "Found #{june_2012_spammers.to_s} recent spammers."
      $stdout.puts "Found #{inactive_users.to_s} other inactive users."
      week_num += 1
      users = get_users(week_num, only_inactive)
    end
  end

  def do_loop(users, oldest_user_created_at, week_num, only_inactive)
    return (users.count > 0) if only_inactive
    oldest_user_created_at < (week_num+1).weeks.ago.to_i
  end

  def get_users(week_num, only_inactive=nil)
    users = User.find(:all, :conditions => "created_at < '#{week_num.weeks.ago}' and created_at > '#{(week_num+1).weeks.ago}'")
    return users unless only_inactive
    users.select do |user|
      user_is_inactive?(user) && (ENV['only_spammers'] ? user_is_spammer?(user) : true)
    end
  end

  def user_is_spammer?(user)
    if user.email =~ /hotmail.com$/
      return user.login =~ /^\w*\d+\w*$/
    elsif user.email =~ /^(.*)@yahoo.co.uk$/
      return user.login == $1
    end
    false
  end

  def user_is_inactive?(user)
    participations = user.try(:user_participations)
    (participations.nil? || participations.empty?) && user.groups.empty?
  end

  def user_has_not_logged_in(user)
    if (user.last_seen_at.nil? || user.last_seen_at == 0) && (user.created_at.to_i > 1.year.ago.to_i)
      return false
    end
    user.last_seen_at.to_i < 1.year.ago.to_i
  end

end
 