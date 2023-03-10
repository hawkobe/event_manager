require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'time'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def clean_phone_number(phone_number)
  formatted_number = phone_number.gsub(/[^0-9]/, "")

  if formatted_number.length == 10
    formatted_number.insert(0, '(').insert(4, ')').insert(8, '-')
  elsif formatted_number.length == 11 && formatted_number[0] == "1"
    formatted_number[1..10].insert(0, '(').insert(4, ')').insert(8, '-')
  else
    "Bad phone number"
  end
end

def calculate_most_frequent_time(array)
  array.max_by{ |value| array.count(value) }
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue 
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end


puts 'EventManager initialized.'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('form_letter.erb')
erb_template = ERB.new template_letter
registration_hours = []
registration_days = []

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  phone_number = clean_phone_number(row[:homephone])
  legislators = legislators_by_zipcode(zipcode)
  registration_hours << Time.strptime(row[:regdate], "%m/%d/%y %H:%M").strftime("%I %p")
  registration_days << Time.strptime(row[:regdate], "%m/%d/%y %H:%M").strftime("%A")
  form_letter = erb_template.result(binding)

  save_thank_you_letter(id, form_letter)
end

puts "The hour people most frequently registered was #{calculate_most_frequent_time(registration_hours)}"
puts "The day people most frequently registered was #{calculate_most_frequent_time(registration_days)}"