require 'prawn'
require "prawn/table"
require 'date'
require 'json'

require 'xmlsimple'
data = XmlSimple.xml_in('invoice.xml')

pdf = Prawn::Document.new

pdf.define_grid(columns: 5, rows: 8, gutter: 10)

pdf.repeat(:all) do
  logo_path = File.expand_path('../../../image/gravatar.png', __FILE__)

  pdf.image logo_path, vposition: :top, width: 50, height: 30, scale: ENV['LOGO_SCALE']

  pdf.grid([0,3], [1,4]).bounding_box do
    pdf.text 'INVOICE', align: :right, size: 18
    pdf.move_down 4

    pdf.text "Invoice Number: #{data['ID'][0]}", align: :right
    pdf.move_down 2
    pdf.text "Issuer Date: #{data['IssueDate'][0]}", align: :right
    pdf.text "Shipment Date: #{data['Delivery'][0]['ActualDeliveryDate'][0]}", align: :right
  end
end

pdf.grid([1,0], [6,4]).bounding_box do

  # address block on first page only
  if pdf.page_number == 1
    to_name = data['AccountingCustomerParty'][0]['Party'][0]["PartyName"][0]['Name'][0]
    from_name = data['AccountingSupplierParty'][0]['Party'][0]["PartyName"][0]['Name'][0]
    to_address = data['Delivery'][0]['DeliveryLocation'][0]['Address'][0]
    from_address = data['AccountingSupplierParty'][0]['Party'][0]['PostalAddress'][0]
    
    from_contacts = data['AccountingCustomerParty'][0]['Party'][0]['Contact'][0] 
    person = data['AccountingCustomerParty'][0]['Party'][0]['Person'][0]

 #  pdf.move_down 2
    to = '<b>To:</b>'
    to << "\n#{to_name}"
    to << "\n#{to_address['StreetName'][0]}"
    unless (street2 = to_address['AdditionalStreetName']).nil? || street2.empty?
      to << " #{street2[0]}" 
    end
    to << "\n#{to_address['CityName'][0]}"
    to << "\n#{to_address['CountrySubentity'][0]}" unless to_address['CountrySubentity'].nil? || to_address['CountrySubentity'].empty?
    to << " #{to_address['PostalZone'][0]}"
    to << "\n#{to_address['Country'][0]['IdentificationCode'][0]['content']}"
    
    from = '<b>From: </b>'
    from << "\n#{from_name}"
    from << "\n#{from_address['StreetName'][0]}"
    unless (street2 = from_address['AdditionalStreetName']).nil? || street2.empty?
      from << " #{street2[0]}" 
    end
    from << "\n#{from_address['CityName'][0]}"
    from << "\n#{from_address['CountrySubentity'][0]}" unless from_address['CountrySubentity'].nil? || from_address['CountrySubentity'].empty?
    from << " #{from_address['PostalZone'][0]}"
    from << "\n#{from_address['Country'][0]['IdentificationCode'][0]['content']}"
    from << "\nContact:"
    from << " #{person['FirstName'][0]}" unless person['FirstName'].nil?
    from << " #{person['MiddleName'][0]}" unless person['MiddleName'].nil?
    from << " #{person['FamilyName'][0]}" unless person['FamilyName'].nil?
    from << "\nTelephone: #{from_contacts['Telephone'][0]}" unless from_contacts['Telephone'].nil?
    from << "\nFax: #{from_contacts['Telefax'][0]}" unless from_contacts['Telefax'].nil?
    from << "\nEmail: #{from_contacts['ElectronicMail'][0]}" unless from_contacts['ElectronicMail'].nil?
    
    
    
    data_address = [[to,from]]
    
    pdf.table(data_address, position: :center, :cell_style => { border_width: 0, size: 10, inline_format: true})
     
  end
end

# CONTENT
pdf.grid([2,0], [6,4]).bounding_box do

  # address block on first page only


  line_item_rows = [["Product", "Description","Qty", "Unit Price","Extended
Amount", "Tax Total"]]
   
  data['InvoiceLine'].each do |invoice_line|
    next if invoice_line.empty?
    item_qty = invoice_line['InvoicedQuantity'][0]['content']
    ext_amount = invoice_line['LineExtensionAmount'][0]['content']
    price = invoice_line['Price'][0]
    item = invoice_line['Item'][0]

    name = item['Name'][0]
    description = item['Description'][0]['content'] unless item['Description'].nil?
    price_amount = price['PriceAmount'][0]['content'] 
    
    tax_total = invoice_line['TaxTotal'][0]['TaxAmount'][0]['content'] 
   
    line_item_rows << [name, description,item_qty,price_amount, ext_amount,tax_total] #, item['rate'], item['quantity'] * item['rate']]
  end

  pdf.move_down 20
  pdf.table line_item_rows, :cell_style => { size: 10} do
    row(0).font_style = :bold
    columns(1..3).align = :right
    self.row_colors = ['DDDDDD', 'FFFFFF']
    self.header = true
  end

  pdf.move_down 15
  pdf.text "Total Price: #{data['item_total']}", size: 16, style: :bold
end


pdf.render_file "invoice.pdf"

