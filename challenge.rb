require 'json'

# Method to safely access a field, returning nil if not present or invalid
def safe_get(data, key, default = nil)
  data[key] || default
end

# Load JSON files with error handling
begin
  companies_file = File.read('companies.json')
  users_file = File.read('users.json')
  companies = JSON.parse(companies_file)
  users = JSON.parse(users_file)
rescue Errno::ENOENT
  puts "Error: One or more JSON files could not be found."
  exit
rescue JSON::ParserError
  puts "Error: JSON parsing failed. Please check the format of the input files."
  exit
end

# Open output file
File.open('output.txt', 'w') do |file|
  # Process companies ordered by company id
  companies.sort_by { |company| safe_get(company, 'id', Float::INFINITY) }.each do |company|
    company_id = safe_get(company, 'id')
    company_name = safe_get(company, 'name', 'Unknown Company')
    top_up_amount = safe_get(company, 'top_up', 0)
    company_email_status = safe_get(company, 'email_status', false)

    # Skip if company_id is missing or invalid
    next if company_id.nil?

    file.puts "Company Id: #{company_id}"
    file.puts "Company Name: #{company_name}"

    # Initialize totals and lists for emailed and non-emailed users
    total_top_up = 0
    emailed_users = []
    non_emailed_users = []

    # Get active users for the current company and sort by last name
    company_users = users.select { |user| safe_get(user, 'company_id') == company_id && safe_get(user, 'active_status', false) }
                         .sort_by { |user| safe_get(user, 'last_name', '') }

    company_users.each do |user|
      user_name = "#{safe_get(user, 'last_name', 'Unknown')}, #{safe_get(user, 'first_name', 'Unknown')}"
      user_email = safe_get(user, 'email', 'No Email')
      user_tokens = safe_get(user, 'tokens', 0)
      user_email_status = safe_get(user, 'email_status', false)
      new_token_balance = user_tokens + top_up_amount

      # Prepare output based on email status
      if user_email_status && company_email_status
        emailed_users << "#{user_name}, #{user_email}\n  Previous Token Balance, #{user_tokens}\n  New Token Balance #{new_token_balance}"
      else
        non_emailed_users << "#{user_name}, #{user_email}\n  Previous Token Balance, #{user_tokens}\n  New Token Balance #{new_token_balance}"
      end

      # Add top up amount to total
      total_top_up += top_up_amount
    end

    # Write users emailed and not emailed to the file
    if emailed_users.any?
      file.puts "Users Emailed:"
      emailed_users.each { |user| file.puts user }
    end

    if non_emailed_users.any?
      file.puts "Users Not Emailed:"
      non_emailed_users.each { |user| file.puts user }
    end

    # Write total top up for the company
    file.puts "Total amount of top ups for #{company_name}: #{total_top_up}"
    file.puts "\n"
  end
end

puts "Output has been written to output.txt"
