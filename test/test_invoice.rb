require 'helper'

class TestInvoice < Test::Unit::TestCase
  
  should "start a new invoice" do
    invoice = InvoicePDF::Invoice.new(:company => 'Company Name LTD', :bill_to => 'John Smith', :notes => 'Notes Sample Text.')
    assert_equal 'Company Name LTD', invoice.company
  end
  
  should "insert a new item into the invoice" do
    invoice = InvoicePDF::Invoice.new({ :company => 'Company Name LTD', :bill_to => 'John Smith', :notes => 'Notes Sample Text.' })
    invoice.items << InvoicePDF::LineItem.new({ :description => 'This is a line item', :price => 400, :quantity => 100 })
    assert_equal 1, invoice.items.length
  end

  should "subtotal should equal 40000" do
    invoice = InvoicePDF::Invoice.new({ :company => 'Company Name LTD', :bill_to => 'John Smith', :notes => 'Notes Sample Text.' })
    invoice.items << InvoicePDF::LineItem.new({ :description => 'This is a line item', :price => 400, :quantity => 100 })
    assert_equal 40000, invoice.subtotal
  end

  should "have paid half of the invoice" do
    invoice = InvoicePDF::Invoice.new({ :company => 'Company Name LTD', :bill_to => 'John Smith', :notes => 'Notes Sample Text.' })
    invoice.items << InvoicePDF::LineItem.new({ :description => 'This is a line item', :price => 400, :quantity => 100 })
    invoice.paid = 20000
    assert_equal 20000, invoice.total_due
  end

  should "save the PDF" do
    invoice = InvoicePDF::Invoice.new({ :company => 'Company Name LTD', :bill_to => 'John Smith', :notes => 'Notes Sample Text.' })

    40.times do |i|
      invoice.items << InvoicePDF::LineItem.new({ :description => "This is a line item#{i}", :price => rand(100..500), :quantity => rand(1..100) })
    end
    invoice.paid = 20000
    invoice.save
    assert_equal true, File.exist?('invoice.pdf')
  end

  should "render pdf" do
    invoice = InvoicePDF::Invoice.new({ :company => 'Company Name LTD', :bill_to => 'John Smith', :notes => 'Notes Sample Text.' })

    40.times do |i|
      invoice.items << InvoicePDF::LineItem.new({ :description => "This is a line item#{i}", :price => rand(100..500), :quantity => rand(1..100) })
    end
    invoice.paid = 20000
    pdf = invoice.render
    assert_equal true, (pdf.class == Prawn::Document)
  end
end
