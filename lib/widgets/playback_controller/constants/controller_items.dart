import 'package:provider/provider.dart';
import 'package:fluent_ui/fluent_ui.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../../utils/api/play_mode.dart';
import '../../../utils/api/play_pause.dart';
import '../../../utils/api/play_play.dart';
import '../../../utils/api/play_previous.dart';
import '../../../utils/dialogs/play_queue_dialog.dart';
import '../../../widgets/playback_controller/fullscreen_button.dart';
import '../../../widgets/playback_controller/utils/playback_mode.dart';
import '../../../providers/status.dart';
import '../../../providers/volume.dart';
import '../../../providers/full_screen.dart';

import '../next_button.dart';
import '../volume_button.dart';
import '../queue_button.dart';
import '../previous_button.dart';
import '../cover_wall_button.dart';
import '../play_pause_button.dart';
import '../playback_mode_button.dart';

class ControllerEntry {
  final String id;
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget Function(BuildContext context) controllerButtonBuilder;
  final MenuFlyoutItem Function(BuildContext context) flyoutEntryBuilder;

  ControllerEntry({
    required this.id,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.controllerButtonBuilder,
    required this.flyoutEntryBuilder,
  });
}

var controllerItems = [
  ControllerEntry(
      id: 'previous',
      icon: Symbols.skip_previous,
      title: "Previous",
      subtitle: "Go to the previous track",
      controllerButtonBuilder: (context) {
        final statusProvider = Provider.of<PlaybackStatusProvider>(context);
        final notReady = statusProvider.notReady;

        return PreviousButton(disabled: notReady);
      },
      flyoutEntryBuilder: (context) {
        final statusProvider = Provider.of<PlaybackStatusProvider>(context);
        final notReady = statusProvider.notReady;

        return MenuFlyoutItem(
          leading: const Icon(Symbols.skip_previous),
          text: const Text('Previous'),
          onPressed: notReady
              ? null
              : () {
                  Flyout.of(context).close();
                  playPrevious();
                },
        );
      }),
  ControllerEntry(
    id: 'toggle',
    icon: Symbols.play_arrow,
    title: "Play/Pause",
    subtitle: "Toggle between play and pause",
    controllerButtonBuilder: (context) {
      final statusProvider = Provider.of<PlaybackStatusProvider>(context);
      final status = statusProvider.playbackStatus;
      final notReady = statusProvider.notReady;

      return PlayPauseButton(
        disabled: notReady,
        state: status?.state ?? "Stopped",
      );
    },
    flyoutEntryBuilder: (context) {
      final statusProvider = Provider.of<PlaybackStatusProvider>(context);
      final status = statusProvider.playbackStatus;
      final notReady = statusProvider.notReady;

      return MenuFlyoutItem(
        leading: status?.state == "Playing"
            ? const Icon(Symbols.pause)
            : const Icon(Symbols.play_arrow),
        text: status?.state == "Playing"
            ? const Text('Pause')
            : const Text('Play'),
        onPressed: notReady
            ? null
            : () {
                Flyout.of(context).close();
                status?.state == "Playing" ? playPause() : playPlay();
              },
      );
    },
  ),
  ControllerEntry(
    id: 'next',
    icon: Symbols.skip_next,
    title: "Next",
    subtitle: "Go to the next track",
    controllerButtonBuilder: (context) {
      final statusProvider = Provider.of<PlaybackStatusProvider>(context);
      final notReady = statusProvider.notReady;

      return NextButton(disabled: notReady);
    },
    flyoutEntryBuilder: (context) {
      final statusProvider = Provider.of<PlaybackStatusProvider>(context);
      final notReady = statusProvider.notReady;

      return MenuFlyoutItem(
        leading: const Icon(Symbols.skip_next),
        text: const Text('Next'),
        onPressed: notReady
            ? null
            : () {
                Flyout.of(context).close();
                playPrevious();
              },
      );
    },
  ),
  ControllerEntry(
    id: 'volume',
    icon: Symbols.volume_up,
    title: "Volume",
    subtitle: "Adjust the volume",
    controllerButtonBuilder: (context) => const VolumeButton(),
    flyoutEntryBuilder: (context) {
      final volumeProvider = Provider.of<VolumeProvider>(context);

      return MenuFlyoutItem(
        leading: Icon(
          volumeProvider.volume > 0.3
              ? Symbols.volume_up
              : volumeProvider.volume > 0
                  ? Symbols.volume_down
                  : Symbols.volume_mute,
        ),
        text: SizedBox(
          width: 100,
          height: 20,
          child: Stack(
            alignment: Alignment.centerLeft,
            clipBehavior: Clip.none,
            children: [
              Positioned(
                top: 0,
                left: -24.0,
                right: -28.0,
                child: Transform.scale(
                  scale: 0.8,
                  child: const VolumeController(
                    width: 120,
                    height: 20,
                    vertical: false,
                  ),
                ),
              )
            ],
          ),
        ),
        onPressed: () {},
      );
    },
  ),
  ControllerEntry(
    id: 'mode',
    icon: Symbols.east,
    title: "Playback Mode",
    subtitle: "Switch between sequential, repeat, or shuffle",
    controllerButtonBuilder: (context) => const PlaybackModeButton(),
    flyoutEntryBuilder: (context) {
      Typography typography = FluentTheme.of(context).typography;
      Color accentColor = Color.alphaBlend(
        FluentTheme.of(context).inactiveColor.withAlpha(100),
        FluentTheme.of(context).accentColor,
      );

      final statusProvider = Provider.of<PlaybackStatusProvider>(context);
      final status = statusProvider.playbackStatus;

      final currentMode =
          PlaybackModeExtension.fromValue(status?.playbackMode ?? 0);

      return MenuFlyoutSubItem(
        leading: Icon(
          modeToIcon(currentMode),
        ),
        text: const Text('Mode'),
        items: (_) => PlaybackMode.values.map(
          (x) {
            final isCurrent = x == currentMode;

            final color = isCurrent ? accentColor : null;
            return MenuFlyoutItem(
              text: Text(
                modeToLabel(x),
                style: typography.body?.apply(color: color),
              ),
              leading: Icon(
                modeToIcon(x),
                color: color,
              ),
              onPressed: () {
                Flyout.of(context).close();
                playMode(x.toValue());
              },
            );
          },
        ).toList(),
      );
    },
  ),
  ControllerEntry(
    id: 'playlist',
    icon: Symbols.list_alt,
    title: "Playlist",
    subtitle: "View the playback queue",
    controllerButtonBuilder: (context) => QueueButton(),
    flyoutEntryBuilder: (context) {
      return MenuFlyoutItem(
        leading: const Icon(Symbols.list_alt),
        text: const Text('Playlist'),
        onPressed: () {
          Flyout.of(context).close();
          showPlayQueueDialog(context);
        },
      );
    },
  ),
  ControllerEntry(
    id: 'hidden',
    icon: Symbols.hide_source,
    title: "Hidden",
    subtitle: "Content below will be hidden in the others list",
    controllerButtonBuilder: (context) => Container(),
    flyoutEntryBuilder: (context) {
      return MenuFlyoutItem(
        leading: const Icon(Symbols.hide),
        text: const Text('Hidden'),
        onPressed: () {},
      );
    },
  ),
  ControllerEntry(
    id: 'cover_wall',
    icon: Symbols.photo,
    title: "Cover Wall",
    subtitle: "Display cover art for a unique ambience",
    controllerButtonBuilder: (context) => const CoverWallButton(),
    flyoutEntryBuilder: (context) {
      return MenuFlyoutItem(
        leading: const Icon(Symbols.photo),
        text: const Text('Cover Wall'),
        onPressed: () {
          Flyout.of(context).close();
          showCoverArtWall(context);
        },
      );
    },
  ),
  ControllerEntry(
    id: 'fullscreen',
    icon: Symbols.fullscreen,
    title: "Fullscreen",
    subtitle: "Enter or exit fullscreen mode",
    controllerButtonBuilder: (context) => const FullScreenButton(),
    flyoutEntryBuilder: (context) {
      final fullScreen = Provider.of<FullScreenProvider>(context);

      return MenuFlyoutItem(
        leading: fullScreen.isFullScreen
            ? const Icon(Symbols.fullscreen_exit)
            : const Icon(Symbols.fullscreen),
        text: const Text('Fullscreen'),
        onPressed: () {
          Flyout.of(context).close();
          fullScreen.setFullScreen(!fullScreen.isFullScreen);
        },
      );
    },
  ),
];
