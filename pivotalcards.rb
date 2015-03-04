#!/usr/bin/env ruby

# Script to generate PDF cards suitable for planning poker
#Customized for the CRM team at Funding Circle
# from Pivotal Tracker [http://www.pivotaltracker.com/] CSV export.

# Inspired by Bryan Helmkamp's http://github.com/brynary/features2cards/

require 'rubygems'
require 'csv'
require 'ostruct'
require 'term/ansicolor'
require 'prawn'
require 'prawn/layout/grid'

class String; include Term::ANSIColor; end

file = ARGV.first

unless file
  puts "[!] Please provide a path to CSV file"
  exit 1
end

# --- Read the CSV file -------------------------------------------------------

stories = CSV.read(file)
headers = stories.shift

# p headers
# p stories

# --- Hold story in Card class

class Card < OpenStruct
  def type
    @table[:type]
  end
end

# --- Create cards objects

cards = stories.map do |story|
  attrs =  { :title  => story[1]   || '',
             :labels => story[2] || '',
             :body   => story[13]  || '',
             :tasks   => story[20]  || '',
             :type   => story[6]   || '',
             :points => story[7]   || '...',
             :owner  => story[12]  || '.'*50}

  Card.new attrs
end

# p cards

# --- Generate PDF with Prawn & Prawn::Document::Grid

begin

outfile = File.basename(file, ".csv")

Prawn::Document.generate("#{outfile}.pdf",
   :page_layout => :landscape,
   :margin      => [25, 25, 50, 25],
   :page_size   => 'A4') do |pdf|

    @num_cards_on_page = 0

    pdf.font "#{Prawn::BASEDIR}/data/fonts/DejaVuSans.ttf"

    cards.each_with_index do |card, i|

      # --- Split pages
      if i > 0 and i % 4 == 0
        # puts "New page..."
        pdf.start_new_page
        @num_cards_on_page  = 1
      else
        @num_cards_on_page += 1
      end

      # --- Define 2x2 grid
      pdf.define_grid(:columns => 2, :rows => 2, :gutter => 42)
      # pdf.grid.show_all

      row    = (@num_cards_on_page+1) / 4
      column = i % 2

      # p @num_cards_on_page
      # p [ row, column ]

      padding = 12

      cell = pdf.grid( row, column )
      cell.bounding_box do

        pdf.stroke_color = "666666"
 if card.type == "feature"
        pdf.fill_color "00FF66"
      elsif card.type == "chore"
          pdf.fill_color "6699FF"
      elsif card.type == "bug"
        pdf.fill_color "FF6666"
      elsif card.type == "release"
          pdf.fill_color "FF99FF"
        else
        end
        pdf.fill_rectangle [0,240], 375, 240
        pdf.stroke_bounds

        # --- Write content
        pdf.bounding_box [pdf.bounds.left+padding, pdf.bounds.top-padding], :width => cell.width-padding*2 do
          pdf.fill_color = "000000"
          pdf.text card.title, :size => 20
          pdf.text "\n", :size => 14
          pdf.fill_color "000000"

        end

 pdf.text_box card.body,
          :size => 10, :at => [12, 160], :width => cell.width-18, :height => 75, :overflow => [:truncate]
    if card.tasks != ""
      pdf.text_box "Tasks:" + card.tasks,
        :size => 10, :at => [12, 100], :width => cell.width-18
    end

        pdf.fill_color "E60000"
          pdf.text_box card.labels,
          :size => 18, :at => [12, 50], :width => cell.width-18
        pdf.fill_color "999999"
          pdf.text_box "Points: " + card.points,
          :size => 12, :at => [12, 18], :align => :right, :width => cell.width-18 

  end

end

    # --- Footer
    pdf.number_pages "#{outfile}.pdf", {at: [pdf.bounds.left,  -28]}
    pdf.number_pages "<page>/<total>", {at: [pdf.bounds.right-16, -28]}
end

puts ">>> Generated PDF file in '#{outfile}.pdf' with #{cards.size} stories:".black.on_green

cards.each do |card|
  puts "* #{card.title}"
end

rescue Exception
  puts "[!] There was an error while generating the PDF file... What happened was:".white.on_red
  raise
end
