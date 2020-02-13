

class Parser

  def initialize(fetcher)
    @fetcher = fetcher
  end

  def get_url
    nil
  end

  def get_result
    url = self.get_url
    html = @fetcher.fetch_html(url)
    style = @fetcher.identify_style(html)
    data =
        case style
        when :style_classic
          parse_classic(html)
        when :style_modern
          parse_modern(html)
        else
          nil
        end
    if data.nil?
      raise FAStyleError(style)
    end
    @fetcher.cache.save(data)
    data
  end

  def parse_classic(html)
    nil
  end

  def parse_modern(html)
    nil
  end
end


class UserProfileParser < Parser

  def initialize(fetcher, username)
    super(fetcher)
    @username = username
  end

  def get_url
    "/users/#{@username}"
  end

  def parse_classic(html)
    {}
  end
end

fetcher = Fetcher.new(nil, nil)
parser = UserProfileParser.new(fetcher, "username")
p parser.get_result