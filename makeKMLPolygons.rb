#NOTE: You CANNOT run this script without the GEOS Lib installed and Path'd correctly.
#This setup will depend on your OS. This is easily done on Linux, on windows install osgeo4w and path manually (annoying)
require 'rgeo/shapefile'
require 'ruby_kml'

#Specify here the relative path and name to your shapefile set. Exclude the filetype extension.
src = "New_Orleans_Levee_Polygons"

write_to_file = true
puts (write_to_file)? "Will be writing records to file...":nil
kml = KMLFile.new
folder = KML::Folder.new(:name=>src)
ts = Time.now


RGeo::Shapefile::Reader.open("#{src}.shp",:assume_inner_follows_outer => true) do |file|
  puts "File contains #{file.num_records} records."
  file.each do |record|
    points_array = Array.new()
    centroid = record.geometry.centroid
    id_key = record.attributes.keys[0]

    record.geometry.boundary.each do |line|
      line.points.each do |point|
        points_array.push([point.x,point.y])
      end
    end

    folder.features << KML::Placemark.new(
      #These were my naming conventions knowing how my GIS files were set. Your milage may vary
      :name => "#{record.attributes['NAME'] || record.attributes['Name'] } #{ (!record.attributes[id_key].zero? && !record.attributes[id_key].nil? )? "(ID: #{record.attributes[id_key]})":nil }",
      :snippet => KML::Snippet.new(:text=>record.attributes['OBJECTID']),
      :geometry => KML::MultiGeometry.new(
        :features => [

          KML::Polygon.new(
            :altitude_mode => 'clampToGround',
            :outer_boundary_is => KML::LinearRing.new(
              :coordinates=> points_array,
            )
          ),
          KML::Point.new(:coordinates=> {:lat=>centroid.y, :lng=>centroid.x}),
        ]
      )
    )
  end
end

kml.objects << folder
(write_to_file)? File.write("#{src}.kml",kml.render) : (puts kml.render)

puts "Completed conversion in #{Time.now - ts}s"
