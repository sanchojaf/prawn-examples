require 'prawn'
require "prawn/table"
require 'date'
require 'json'

file = File.read('invoice.json')
data = JSON.parse(file)

pdf = Prawn::Document.new

pdf.define_grid(columns: 5, rows: 8, gutter: 10)

font_style = {
  face: ENV['FONT_FACE'],
  size: ENV['FONT_SIZE']
}

pdf.font "Helvetica"

pdf.repeat(:all) do
  logo_path = File.expand_path('../../../image/gravatar.png', __FILE__)

  pdf.image logo_path, vposition: :top, width: 50, height: 30, scale: ENV['LOGO_SCALE']

  pdf.grid([0,3], [1,4]).bounding_box do
    pdf.text 'Print Invoice', align: :right, style: :bold, size: 18
    pdf.move_down 4

    pdf.text "Invoice No: #{data['invoice_number']}", align: :right
    pdf.move_down 2
    pdf.text "Date: #{data['date']}", align: :right
  end
end

# CONTENT
pdf.grid([1,0], [6,4]).bounding_box do

  # address block on first page only
  if pdf.page_number == 1
    bill_address = data['customer']['billing_address']
    ship_address = data['customer']['shipping_address']

    pdf.move_down 2
    address_cell_billing  = pdf.make_cell(content: 'Billing Address', font_style: :bold)
    address_cell_shipping = pdf.make_cell(content: 'Shipping Address', font_style: :bold)

    billing =  "#{bill_address['firstname']} #{bill_address['lastname']}"
    billing << "\n#{bill_address['address1']}"
    billing << "\n#{bill_address['address2']}" unless bill_address['address2'].nil? || bill_address['address2'] == ''
    billing << "\n#{bill_address['city']}"
    billing << "\n#{bill_address['state']} #{bill_address['zipcode']}"
    billing << "\n#{bill_address['country']}"
    billing << "\n#{bill_address['phone']}"

    shipping =  "#{ship_address['firstname']} #{ship_address['lastname']}"
    shipping << "\n#{ship_address['address1']}"
    shipping << "\n#{ship_address['address2']}" unless ship_address['address2'].nil? || ship_address['address2'] == ''
    shipping << "\n#{ship_address['city']}"
    shipping << "\n#{ship_address['state']} #{ship_address['zipcode']}"
    shipping << "\n#{ship_address['country']}"
    shipping << "\n#{ship_address['phone']}"
#    shipping << "\n\n#{'Print Invoice'} #{printable.shipping_methods.join(", ")}"

    data_address = [[address_cell_billing, address_cell_shipping], [billing, shipping]]
    
    
    pdf.table(data_address, position: :center, column_widths: [pdf.bounds.width / 2, pdf.bounds.width / 2])


  end

  pdf.move_down 10
    
  header = [
    pdf.make_cell(content: 'Sku'),
    pdf.make_cell(content: 'Name'),
    pdf.make_cell(content: 'Description'),
    pdf.make_cell(content: 'Price'),
    pdf.make_cell(content: 'Qty'),
    pdf.make_cell(content: 'Total')
  ]
  data_items = [header]

  data['line_items'].each do |item|
    row = [
      item['sku'],
      item['name'],
      item['description'],
      item['rate'],
      item['quantity'],
      item['rate']
    ]
    data_items += [row]
  end


  column_widths = [0.13, 0.37, 0.185, 0.12, 0.075, 0.12].map { |w| w * pdf.bounds.width }

  pdf.table(data_items, header: true, position: :center, column_widths: column_widths) do
    row(0).style align: :center, font_style: :bold
    column(0..2).style align: :left
    column(3..6).style align: :right
  end

  pdf.move_down 10

  # TOTALS
  totals = []
  total = 0

  # Subtotal
  total += data['item_total']
  totals << [pdf.make_cell(content: 'Subtotal'), data['item_total']]

  # Adjustments
  data['adjustments'].each do |adjustment|
    total += adjustment['amount']
    totals << [pdf.make_cell(content: adjustment['label']), adjustment['amount']]
  end

  # Shipments
  data['shipments'].each do |shipment|
    total += shipment['cost']
    totals << [pdf.make_cell(content: shipment['shipping_method']), shipment['cost']]
  end

  # Totals
  totals << [pdf.make_cell(content: 'Order total'), total]

#  # Payments
  total_payments = 0.0
  data['payment_options']['payment_gateways'].each do |payment|
    value = "#{payment['gateway_name']} "
    value += "\n gateway: #{payment['source_type']}"
    value += "\n number: #{payment['number']}"
    value += "\n date: #{payment['updated_at']}"
  
    totals << [
      pdf.make_cell(content: value),
      payment['amount']
    ]
    total_payments += payment['amount']
  end

  totals_table_width = [0.875, 0.125].map { |w| w * pdf.bounds.width }
  pdf.table(totals, column_widths: totals_table_width) do
    row(0..7).style align: :right
    column(0).style borders: []
  end

  pdf.move_down 30

  pdf.text ENV['RETURN_MESSAGE'], align: :right, size: font_style[:size]
end

# Footer
if ENV['USE_FOOTER']
  pdf.repeat(:all) do
    pdf.grid([7,0], [7,4]).bounding_box do

      data  = []
      data << [pdf.make_cell(content: 'VAT', colspan: 2, align: :center)]
      data << [pdf.make_cell(content: '', colspan: 2)]
      data << [pdf.make_cell(content: ENV['FOOTER_LEFT'],  align: :left),
      pdf.make_cell(content: ENV['FOOTER_RIGHT'], align: :right)]

      pdf.table(data, position: :center, column_widths: [pdf.bounds.width / 2, pdf.bounds.width / 2]) do
        row(0..2).style borders: []
      end
    end
  end
end

# Page Number
if ENV['USE_PAGE_NUMBERS']
  string  = "page <page> of <total>"

  options = {
    at: [pdf.bounds.right - 155, 0],
    width: 150,
    align: :right,
    start_count_at: 1,
    color: '000000'
  }

  pdf.number_pages string, options
end


pdf.render_file "invoice.pdf"

