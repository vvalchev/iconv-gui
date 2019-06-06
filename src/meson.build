iconv_gui_sources = [
  'main.vala',
  'window.vala',
]

iconv_gui_deps = [
  dependency('gio-2.0', version: '>= 2.50'),
  dependency('gtk+-3.0', version: '>= 3.22'),
]

gnome = import('gnome')

iconv_gui_sources += gnome.compile_resources('iconv-gui-resources',
  'iconv-gui.gresource.xml',
  c_name: 'iconv_gui'
)

executable('iconv-gui', iconv_gui_sources,
  vala_args: '--target-glib=2.50',  dependencies: iconv_gui_deps,
  install: true,
)
