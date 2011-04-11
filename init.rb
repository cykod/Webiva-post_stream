# Copyright (C) 2009 Pascal Rettig.

webiva_remove_load_paths(__FILE__)

yaml_file = File.join(File.expand_path("../config/oembed_links.yml", __FILE__))
if File.exists?(yaml_file)
  OEmbed::register_yaml_file(yaml_file)
end
