const stdx = @import("stdx");
const graphics = @import("graphics");
const Color = graphics.Color;
const platform = @import("platform");

const ui = @import("../ui.zig");
const w = ui.widgets;

// Wrappers over existing widgets to present like a option setting widget.

pub const SliderOption = SliderOptionBase(false);
pub const SliderFloatOption = SliderOptionBase(true);

fn SliderOptionBase(comptime is_float: bool) type {
    const Inner = if (is_float) w.SliderFloatT else w.SliderT;
    const InnerProps = ui.WidgetProps(Inner);
    return struct {
        props: struct {
            label: []const u8 = "Slider",
            slider: InnerProps,
        },

        inner: ui.WidgetRef(Inner),

        const Self = @This();

        pub fn build(self: *Self, c: *ui.BuildContext) ui.FrameId {
            return w.Row(.{ .valign = .Center }, &.{
                w.Flex(.{ .flex = 1 },
                    w.Text(.{
                        .text = self.props.label,
                        .color = Color.White,
                        .fontSize = 14,
                    }),
                ),
                w.Flex(.{ .flex = 3, }, 
                    w.Padding(.{ .pad_left = 20 }, 
                        c.build(Inner, .{
                            .bind = &self.inner,
                            .spread = self.props.slider,
                        }),
                    )
                )
            });
        }
    };
}

// TODO: Use .spread like SliderOption
pub const SwitchOption = struct {
    props: struct {
        label: []const u8 = "Switch",
        init_val: bool = false,
        onChange: ?stdx.Function(fn (bool) void) = null,
    },

    inner: ui.WidgetRef(w.SwitchT),

    pub fn isSet(self: *SwitchOption) bool {
        return self.inner.getWidget().isSet();
    }

    pub fn build(self: *SwitchOption, c: *ui.BuildContext) ui.FrameId {
        const S = struct {
            fn onClick(self_: *SwitchOption, _: ui.MouseUpEvent) void {
                self_.inner.getWidget().toggle();
            }
        };
        return w.MouseArea(.{ .onClick = c.funcExt(self, S.onClick) },
            w.Row(.{ .valign = .Center }, &.{
                w.Flex(.{}, 
                    w.Text(.{
                        .text = self.props.label,
                        .fontSize = 14,
                        .color = Color.White,
                    }),
                ),
                w.Switch(.{
                    .bind = &self.inner,
                    .init_val = self.props.init_val,
                    .onChange = self.props.onChange,
                }),
            }),
        );
    }
};