module Jekyll
  class Speakerdeck < Liquid::Tag
    def initialize(name, id, tokens)
      super
      @id = id
    end

    def render(context)
      @id_stripped = @id.strip.tr('"', '')
      %(<p>
        <script async class="speakerdeck-embed" data-id=#{@id} data-ratio="1.3" src="https://speakerdeck.com/assets/embed.js">
        </script>
        </p>)
    end
  end
end

Liquid::Template.register_tag('speakerdeck', Jekyll::Speakerdeck)
