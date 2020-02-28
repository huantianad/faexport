# encoding: utf-8

# scraper.rb - Quick and dirty API for scraping data from FA
#
# Copyright (C) 2015 Erra Boothale <erra@boothale.net>
# Further work: 2020 Deer Spangle <deer@spangle.org.uk>
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
#   * Redistributions of source code must retain the above copyright notice,
#     this list of conditions and the following disclaimer.
#   * Redistributions in binary form must reproduce the above copyright
#     notice, this list of conditions and the following disclaimer in the
#     documentation and/or other materials provided with the distribution.
#   * Neither the name of FAExport nor the names of its contributors may be
#     used to endorse or promote products derived from this software without
#     specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.


class Parser

  def initialize(fetcher)
    @fetcher = fetcher
  end

  def get_path
    nil
  end

  def get_extra_cookie
    nil
  end

  def get_cache_key
    raise NotImplementedError
  end

  def get_result
    path = self.get_path
    @fetcher.cache.add_hash("data:#{get_cache_key}") do
      html = @fetcher.fetch_html(path, get_extra_cookie)
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
      data
    end
  end

  def parse_classic(html)
    nil
  end

  def parse_modern(html)
    nil
  end

private
  def escape(name)
    CGI::escape(name)
  end

  def to_iso8601(date)
    Time.parse(date + ' UTC').iso8601
  end

  def pick_date(tag)
    tag.content.include?('ago') ? tag['title'] : tag.content
  end

  def last_path(path)
    path.split('/').last
  end

  def fa_url(path)
    path = @fetcher.strip_leading_slash(path)
    "#{@fetcher.fa_address}/#{path}"
  end

  def build_submission_classic(elem)
    if elem
      id = elem['id']
      title =
          if elem.at_css('figcaption')
            elem.at_css('figcaption').at_css('p').at_css('a').content
          elsif elem.at_css('span')
            elem.at_css('span').content
          else
            ""
          end
      author_elem = elem.at_css('figcaption') ? elem.at_css('figcaption').css('p')[1].at_css('a') : nil
      sub = {
          id: id ? id.gsub(/sid[-_]/, '') : '',
          title: title,
          thumbnail: "https:#{elem.at_css('img')['src']}",
          link: fa_url(elem.at_css('a')['href'][1..-1]),
          name: author_elem ? author_elem.content : '',
          profile: author_elem ? fa_url(author_elem['href'][1..-1]) : '',
          profile_name: author_elem ? last_path(author_elem['href']) : ''
      }
      sub[:fav_id] = elem['data-fav-id'] if elem['data-fav-id']
      sub
    else
      nil
    end
  end

  def get_current_user_classic(html, url)
    name_elem = html.at_css("a#my-username")
    if name_elem.nil?
      raise FALoginError.new(url)
    end
    {
        "name": name_elem.content.strip.gsub(/^~/, ''),
        "profile": fa_url(name_elem['href'][1..-1]),
        "profile_name": last_path(name_elem['href'])
    }
  end
end