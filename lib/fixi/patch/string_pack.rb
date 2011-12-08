class String
  def pack
    self.gsub(/\s+/, ' ').strip
  end
end
