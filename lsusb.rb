class USBCBase
  class NotFound < StandardError
  end

  def initialize(path)
    @path = path
  end

  private

  def read_file(name)
    fp = File.join(@path, name.to_s)

    unless File.exist?(fp)
      raise NotFound
    end

    return File.read(File.join(@path, name.to_s)).strip
  end
end

class USBCPort < USBCBase
  def data_role
    d = read_file(__method__)
    return d.scan(/\[(.+)\]/)[0][0]
  end

  def power_role
    d = read_file(__method__)
    return d.scan(/\[(.+)\]/)[0][0]
  end

  def location
    location = ''

    dock = read_file("physical_location/dock")
    if dock != "no"
      location += "Dock "
    end

    lid = read_file("physical_location/lid")
    if lid != "no"
      location += "Lid "
    end

    hp = read_file("physical_location/horizontal_position")
    vp = read_file("physical_location/vertical_position")
    location += "Position: #{vp} #{hp}, "

    p = read_file("physical_location/panel")
    location += "Panel: #{p} "

    return location
  end

  def to_s
    msg = ["#{@path}:"]
    msg << "\t Location: #{location}"
    msg << "\t Data role: #{data_role}"
    msg << "\t Power role: #{power_role}"
    pref = read_file('preferred_role')
    msg << "\t Power Operation role: #{pref} " + (pref || ' ')
    msg << "\t Supported USB-C Specification Revision #{read_file('usb_typec_revision')}"
    pr = read_file('usb_power_delivery_revision')
    msg << "\t Power Delivery Revision: #{pr}" + (pr == "0.0" ? ' (Power Delivery not supported)' : '')
    return msg.join("\n")
  end
end

class USBCPartner < USBCBase
  def to_s
    msg = ["#{@path}:"]
    msg << "\t Accessory Mode role: #{read_file('accessory_mode')}"
    pr = read_file('usb_power_delivery_revision')
    msg << "\t Power Delivery Revision: #{pr}" + (pr == "0.0" ? ' (Power Delivery not supported)' : '')
    msg << "\t Supports Power Delivery: #{read_file('supports_usb_power_delivery')}"
    msg << "\t Advertised alternate mode: #{read_file('supports_usb_power_delivery')}"
    return msg.join("\n")
  end
end

puts Dir.glob("/sys/class/typec/port*").grep(/port[0-9+]$/).map { |p| USBCPort.new(p) }
puts Dir.glob("/sys/class/typec/port*").grep(/port[0-9+]-(cable|partner)$/).map { |p| USBCPartner.new(p) }

