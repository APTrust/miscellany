#
# trello.rb
#
# This script gathers cards from APTrust Trello boards into a single
# HTML page with searchable, sortable table. The table allows for quick
# reporting in a single view.
#
# Requirements:
#
# You must have a Trello API key set in ENV['TRELLO_API_KEY'] and an auth
# token set in ENV['TRELLO_AUTH_TOKEN']. You can get an API key at
# https://trello.com/app-key/ and an auth token at
# https://trello.com/1/authorize?expiration=30days&name=MyPersonalToken&scope=read&response_type=token&key=YOUR_API_KEY_HERE
#
# Usage:
#
# $ ruby trello.rb
#
# ----------------------------------------------------------------------------
require 'json'
require 'net/http'
require 'openssl'
require 'uri'

@all_cards = []

def base_params
  {
    query: '@me is:open',
    idBoards: 'mine',
    modelTypes: 'cards',
    card_fields: 'closed,desc,dateLastActivity,due,labels,name,shortLink,shortUrl',
    cards_limit: 50,
    cards_page: 0,
    card_board: false,
    card_list: true,
    card_members: true,
    card_stickers: false,
    card_attachments: false,
    member_fields: 'fullName,username',
    members_limit: 10,
    partial: false,
    key: ENV['TRELLO_API_KEY'],
    token: ENV['TRELLO_AUTH_TOKEN']
  }
end

def do_request(page)
  params = base_params
  params[:cards_page] = page || 0
  url = URI.parse('https://api.trello.com/1/search?' +  URI.encode_www_form(params))
  http = Net::HTTP.new(url.host, url.port)
  http.use_ssl = true
  http.verify_mode = OpenSSL::SSL::VERIFY_NONE
  request = Net::HTTP::Get.new(url)
  response = http.request(request)
  #puts response.read_body
  return JSON.parse(response.read_body)
end

def add_cards(data)
  data['cards'].each do |card|
    members = card['members'].map { |m| m['fullName'] }.join(', ')
    labels = card['labels'].map { |l| l['name'] }.join(', ')
    due = card['due'] ? card['due'][0..9] : ''
    lastActive = card['dateLastActivity'] ? card['dateLastActivity'][0..9] : ''
    @all_cards.push({
                     id: card['shortLink'],
                     name: card['name'],
                     list: card['list']['name'],
                     labels: labels,
                     members: members,
                     due: due,
                     lastActive: lastActive,
                     closed: card['closed'],
                     url: card['shortUrl'],
                     desc: card['desc']
                   })
  end
  return data['cards'].count > 0
end

def run
  page = 0
  has_more = true
  while has_more
    data = do_request(page)
    has_more = add_cards(data)
    page += 1
  end
  create_report
end

def create_report
  dir = File.dirname(__FILE__)
  html = File.read(File.join(dir, 'trello_template.html'))
  report = html.sub(/\{\{ data \}\}/, table_rows)
  File.write(File.join(dir, 'trello_report.html'), report)
  puts "Report written to #{File.join(dir, 'trello_report.html')}"
end

def table_rows
  rows = []
  @all_cards.each do |card|
    rows.push(create_row(card))
  end
  return rows.join("\n")
end

def create_row(card)
  <<~HEREDOC
    <tr id="#{card[:id]}">
      <td><a href="#{card[:url]}" target="_blank">#{card[:name]}</a></td>
      <td>#{card[:list]}</td>
      <td>#{card[:labels]}</td>
      <td>#{card[:members]}</td>
      <td>#{card[:lastActive]}</td>
      <td>#{card[:due]}</td>
      <!-- td>#{card[:closed]}</td -->
      <td>#{card[:desc]}</td>
    </tr>
  HEREDOC
end

if __FILE__ == $0
  run()
end
