require 'prawn'
require "prawn/table"
require 'date'
require 'json'

file = File.read('invoice.json')
data = JSON.parse(file)

pdf = Prawn::Document.new

pdf.define_grid(columns: 5, rows: 8, gutter: 10)


pdf.text "Invoice \##{data['invoice_number']}", size: 30, style: :bold


  line_item_rows =
    [["Product", "Qty", "Unit Price", "Full Price"]] +
    data['line_items'].map do |item|
      [item['name'], item['quantity'], item['rate'], item['quantity'] * item['rate']]
    end
  
    pdf.move_down 20
    pdf.table line_item_rows do
      row(0).font_style = :bold
      columns(1..3).align = :right
      self.row_colors = ['DDDDDD', 'FFFFFF']
      self.header = true
    end

    pdf.move_down 15
    pdf.text "Total Price: #{data['item_total']}", size: 16, style: :bold



pdf.render_file "invoice.pdf"

