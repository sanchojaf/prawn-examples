require 'prawn'
require "prawn/table"
require 'date'
require 'json'

file = File.read('invoice.json')
data = JSON.parse(file)

pdf = Prawn::Document.new

pdf.font "Helvetica"

# Defining the grid 
# See http://prawn.majesticseacreature.com/manual.pdf
pdf.define_grid(:columns => 5, :rows => 8, :gutter => 10) 

pdf.grid([0,0], [1,1]).bounding_box do 
  pdf.text  "INVOICE", :size => 18
  pdf.text "Invoice No: #{data['invoice_number']}", :align => :left
  pdf.text "Date: #{data['date']}", :align => :left
  pdf.move_down 10
  
  pdf.text "Attn: To whom it may concern "
  pdf.text "Company Name"
  pdf.text "Tel No: 1"
  pdf.text "Fax No: 0`  1"
end

pdf.grid([0,3.6], [1,4]).bounding_box do 
  # Assign the path to your file name first to a local variable.
  logo_path = File.expand_path('../../image/gravatar.jpg', __FILE__)

  # Displays the image in your PDF. Dimensions are optional.
  pdf.image logo_path, :width => 50, :height => 50, :position => :left

  # Company address
  pdf.move_down 10
  pdf.text "#{data['address']['firstname']} #{data['address']['lastname']}", :align => :left
  pdf.text "#{data['address']['address1']}", :align => :left
  unless data['address']['address2'].nil? || data['address']['address2'] == ''
    pdf.text "#{data['address']['address2']}", :align => :left
  end
  pdf.text "#{data['address']['city']}", :align => :left
  pdf.text "#{data['address']['zipcode']} #{data['address']['state']}", :align => :left
  pdf.text "#{data['address']['country']}", :align => :left
  pdf.text "Phone No: #{data['address']['phone']}", :align => :left
end

pdf.text "Details of Invoice", :style => :bold_italic
pdf.stroke_horizontal_rule

pdf.move_down 10
items = [["No","Name", "Qt.", "Rate"]]

data['line_items']

total = 0
data['line_items'].each_with_index.each do |item, i|
  total += item['quantity'] * item['rate']

  items<< [
    i + 1,
    item['name'],
    item['quantity'],
    item['rate'],
  ]
end

total +=  data["shipping_charge"] + data["adjustment"]
items += [["", "Total", "", "#{total}"]]


pdf.table items, :header => true, 
  :column_widths => { 0 => 50, 1 => 350, 3 => 100}, :row_colors => ["d2e3ed", "FFFFFF"] do
    style(columns(3)) {|x| x.align = :right }
end


pdf.move_down 40
pdf.text "Terms & Conditions of Sales"
pdf.text "#{data['terms']}"

pdf.move_down 40
pdf.text "#{data['notes']}", :style => :italic

pdf.move_down 20
pdf.text "..............................."
pdf.text "Signature/Company Stamp"

pdf.move_down 10
pdf.stroke_horizontal_rule

pdf.bounding_box([pdf.bounds.right - 50, pdf.bounds.bottom], :width => 60, :height => 20) do
  pagecount = pdf.page_count
  pdf.text "Page #{pagecount}"
end

pdf.render_file "invoice.pdf"
