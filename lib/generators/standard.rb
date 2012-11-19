module InvoicePDF

  # Generators should be contained within the <tt>InvoicePDF::Generators</tt> module.
  module Generators

    # The default InvoicePDF generator.
    class Standard
      include InvoicePDF::Helpers

      # Constructor here for future use... maybe.
      def initialize( options = {} ); end

      # Called from <tt>InvoicePDF::Invoice.save</tt>. +invoice+ is the <tt>InvoicePDF::Invoice</tt> instance.
      def create_pdf( invoice, to_file = true, hide_quantity_column = false, hide_price_column = false )
        money_maker_options = {
            :currency_symbol => invoice.currency,
            :delimiter => invoice.separator,
            :decimal_symbol => invoice.decimal,
            :after_text => invoice.currency_text
        }

        Prawn::Document.new(
            :dpi => 72,
            :page_size => 'A4',
            :page_layout => :portrait

        ) do |pdf|
          pdf.move_down 10

          # Set the default type
          pdf.font 'Helvetica', :size => 9

          # Draw the company name
          pdf.text invoice.company, :style => :bold, :size => 20

          # Invoice information
          pdf.bounding_box [ pdf.bounds.right - 200, pdf.bounds.top - 2 ], :width => 250 do
            data = [
                [ Prawn::Table::Cell::Text.new( pdf, [0,0], :content => "<b>Invoice num</b>", :inline_format => true), invoice.number.to_s ],
                [ Prawn::Table::Cell::Text.new( pdf, [0,0], :content => "<b>Invoice Date</b>", :inline_format => true), invoice.invoice_date.to_s ],
                [ Prawn::Table::Cell::Text.new( pdf, [0,0], :content => "<b>Due Date</b>", :inline_format => true), invoice.due_date.to_s ]
            ]
            data.insert( 1, [ Prawn::Table::Cell::Text.new( pdf, [0,0], :content => "<b>PO number</b>", :inline_format => true), invoice.po_number ] ) unless invoice.po_number.nil?

            pdf.table(data,  :cell_style => { :borders => [] }) do |table|
              table.column_widths = { 0 => 70, 1 => 150 }
            end

          end
          # End bounding_box

          pdf.move_down 65

          var_y = pdf.y

          # Bill to section
          pdf.bounding_box [ 0, var_y ], :width => ( pdf.bounds.right / 3 ) do
            pdf.text 'Bill To', :style => :bold
            pdf.text "#{invoice.bill_to}\n#{invoice.bill_to_address}"
          end
          # End bill to section

          # Company address section
          pdf.bounding_box [ ( pdf.bounds.right / 3 ), var_y ], :width => ( pdf.bounds.right / 3 ) do
            pdf.text 'Pay To', :style => :bold
            pdf.text "#{invoice.company}\n#{invoice.company_address}"
          end
          # End company address section

          pdf.move_down 40

          # Create items array for storage of invoice items
          items = []
          headers = []
          headers.push('Description')
          headers.push('Qty') if !hide_quantity_column
          headers.push('Price') if !hide_price_column
          headers.push('Total')

          items << headers

          cell_options = {:inline_format => true, :align => :right, :background_color => 'ffffff', :colspan => headers.length-1}
          cell_options_sum_number = { :background_color => 'f00ccf' }

          invoice.items.map { |item|
            columns = []
            columns << item.description
            columns << item.quantity if !hide_quantity_column
            columns << money_maker(item.price, money_maker_options) if !hide_price_column
            columns << money_maker(item.total, money_maker_options)
            items << columns
            #items << [ item.description, item.quantity, money_maker(item.price, money_maker_options), money_maker(item.total, money_maker_options) ]
          }

          # Insert subtotal
          items << [ create_cell(pdf, "<b>Subtotal</b>", cell_options), create_cell( pdf, money_maker(invoice.subtotal, money_maker_options),cell_options_sum_number)  ]

          # Insert discount
          items << [ create_cell(pdf, "<b>Discount (#{invoice.discount}%)</b>", cell_options), create_cell( pdf, money_maker(invoice.discount_amount, money_maker_options),cell_options_sum_number)  ] if invoice.discount_amount > 0

          # Insert tax amount
          items << [ create_cell(pdf, "<b>Tax (#{invoice.tax}%)</b>", cell_options), create_cell( pdf, money_maker(invoice.tax_amount, money_maker_options),cell_options_sum_number)  ] if invoice.tax_amount > 0

          # Insert total
          items << [ create_cell(pdf, "<b>Total</b>", cell_options), create_cell( pdf, money_maker(invoice.total, money_maker_options),cell_options_sum_number)  ]

          # Insert amount paid
          items << [ create_cell(pdf, "<b>Amount Paid</b>", cell_options), create_cell( pdf, money_maker(invoice.paid, money_maker_options),cell_options_sum_number)  ] if invoice.paid > 0

          # Insert total due
          items << [ create_cell(pdf, "<b>Amount Due</b>", cell_options), create_cell( pdf, money_maker(invoice.total_due, money_maker_options),cell_options_sum_number)  ]

          # Create items table
          pdf.table(items,
                    :header => true,
                    :width => pdf.bounds.right,
                    :header => true,
                    :row_colors => [ 'ffffff', 'f0f0f0' ],
                    :cell_style => {
                        :borders => [:left, :right, :top, :bottom],
                        :border_color => '0000ff',
                        :border_width => 0
                    }) do |table|
            table.column_widths = { 1 => 50, 2 => 75, 3 => 75 }
            table.rows(0).background_color = 'f00ccf'  # Header color
          end

          unless invoice.notes.nil?
            pdf.move_down 50
            pdf.text 'Notes', :size => 10, :style => :bold
            pdf.text invoice.notes, :size => 8
          end

          pdf.render_file "#{invoice.file_path}/#{invoice.file_name}" if to_file

        end

      end

      private

      def create_cell( pdf, content, options = {})
        options.merge!({:content => content})
        Prawn::Table::Cell::Text.new( pdf, [0,0], options )
      end

    end

  end
end