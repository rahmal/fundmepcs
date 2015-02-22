# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

RConfig.computers.each do |key, data|
  Product.create(
    name: data.name,
    description: data.desc,
    cost: (data.cost * 100),
    brand: data.brand,
    series: data.series,
    model: data.model,
    os: data.os,
    processor: data.processor,
    battery: data.battery,
    memory: data.memory,
    storage: data.storage,
    screen: data.screen,
    wifi: data.wifi,
    weight: data.weight,
    dimensions: data.dimensions,
    release_date: Date.parse(data.release_date),
    image: "/assets/products/#{key}.jpg"
  )
end