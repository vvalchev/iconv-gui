/* window.vala
 *
 * Copyright 2019 fire
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */
using Gtk;
using Gdk;
using GLib;

namespace IconvGui {

/**
 * Define a list of data types called "targets" that a destination widget will
 * accept. The string type is arbitrary, and negotiated between DnD widgets by
 * the developer. An enum or Quark can serve as the integer target id.
 */
enum Target {
    INT32,
    STRING,
    ROOTWIN,
}

/* datatype (string), restrictions on DnD (Gtk.TargetFlags), datatype (int) */
const TargetEntry[] target_list = {
    { "text/uri-list", 0, Target.STRING },
};


    [GtkTemplate (ui = "/org/gnome/Iconv-Gui/window.ui")]
    public class Window : Gtk.ApplicationWindow {
        [GtkChild]
        Gtk.Image dropPoint;
        [GtkChild]
        Gtk.Label statusBar;
        [GtkChild]
        Gtk.Entry fromEntry;
        [GtkChild]
        Gtk.Entry toEntry;

        GLib.Settings settings;

        public Window (Gtk.Application app) {
            Object (application: app);
            settings = new GLib.Settings("org.gnome.Iconv-Gui");
            settings.bind("from-encoding", fromEntry, "text", SettingsBindFlags.DEFAULT);
            settings.bind("to-encoding", toEntry, "text", SettingsBindFlags.DEFAULT);

            statusBar.label = "";

            Gtk.drag_dest_set (
                dropPoint,                // widget that will accept a drop
                DestDefaults.MOTION       // default actions for dest on DnD
                | DestDefaults.HIGHLIGHT,
                target_list,              // lists of target to support
                DragAction.COPY           // what to do with data after dropped
            );

            // All possible destination signals
            dropPoint.drag_drop.connect(this.on_drag_drop);
            dropPoint.drag_data_received.connect(this.on_drag_data_received);


        }

        private bool convert_file (string uri) {
                var file = File.new_for_uri(uri);
                if (file.query_exists()) {
                    print("Converting file %s", uri);
                    try {
                        Converter converter = new CharsetConverter("utf-8", "windows-1251");
                        InputStream stream = file.read();
                        stream = new GLib.ConverterInputStream(stream, converter);
                        var data = stream.read_bytes(200*1024); // 200k
                        file
                            .replace(null, true, FileCreateFlags.NONE)
                            .write(data.get_data());

                        statusBar.label = @"$uri - Done!";
                        return true;
                    } catch (Error e) {
                        statusBar.label = "Error: %s".printf(e.message);
                    }

                } else {
                    statusBar.label = @"File $uri doesn't exists!";
                    print(statusBar.label);
                }
                return false;
        }

        /**
     * Emitted when the user releases (drops) the selection. It should check
     * that the drop is over a valid part of the widget (if its a complex
     * widget), and itself to return true if the operation should continue. Next
     * choose the target type it wishes to ask the source for. Finally call
     * Gtk.drag_get_data which will emit "drag_data_get" on the source.
     */
    private bool on_drag_drop (Widget widget, DragContext context,
                               int x, int y, uint time)
    {
        print ("%s: on_drag_drop\n", widget.name);

        // Check to see if (x, y) is a valid drop site within widget
        bool is_valid_drop_site = true;

        // If the source offers a target
        if (context.list_targets() != null) {
            // Choose the best target type
            var target_type = (Atom) context.list_targets().nth_data (Target.STRING);

            // Request the data from the source.
            Gtk.drag_get_data (
                    widget,         // will receive 'drag_data_received' signal
                    context,        // represents the current state of the DnD
                    target_type,    // the target type we want
                    time            // time stamp
                );
        } else {
            // No target offered by source => error
            is_valid_drop_site = false;
        }

        return is_valid_drop_site;
    }

    /**
     * Emitted when the data has been received from the source. It should check
     * the SelectionData sent by the source, and do something with it. Finally
     * it needs to finish the operation by calling Gtk.drag_finish, which will
     * emit the "data_delete" signal if told to.
     */
    private void on_drag_data_received (Widget widget, DragContext context,
                                        int x, int y,
                                        SelectionData selection_data,
                                        uint target_type, uint time)
    {
        bool dnd_success = false;
        bool delete_selection_data = false;

        print ("%s: on_drag_data_received\n", widget.name);

        // Deal with what we are given from source
        if ((selection_data != null) && (selection_data.get_length() >= 0)) {
            if (context.get_suggested_action() == DragAction.ASK) {
                // Ask the user to move or copy, then set the context action.
            }

            // Check that we got the format we can use
            switch (target_type) {
            case Target.STRING:
                dnd_success = convert_file(  ((string) selection_data.get_data()).strip() );
                break;
            default:
                print ("nothing good");
                break;
            }
        }

        if (dnd_success == false) {
            print ("DnD data transfer failed!\n");
        }

        Gtk.drag_finish (context, dnd_success, delete_selection_data, time);
    }
    }
}
