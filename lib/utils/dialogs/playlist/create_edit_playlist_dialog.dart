import 'package:fluent_ui/fluent_ui.dart';

import '../../../utils/api/update_playlist.dart';
import '../../../utils/api/create_playlist.dart';
import '../../../utils/api/get_playlist_by_id.dart';
import '../../../utils/dialogs/unavailable_dialog_on_band.dart';
import '../../../widgets/no_shortcuts.dart';
import '../../../widgets/responsive_dialog_actions.dart';
import '../../../screens/collection/utils/collection_data_provider.dart';
import '../../../messages/playlist.pb.dart';
import '../../../messages/collection.pb.dart';
import '../../../utils/l10n.dart';

import '../../api/fetch_collection_group_summary_title.dart';

import '../clean_group_titles.dart';

class CreateEditPlaylistDialog extends StatefulWidget {
  final int? playlistId;
  final void Function(Playlist?) $close;

  const CreateEditPlaylistDialog({
    super.key,
    this.playlistId,
    required this.$close,
  });

  @override
  CreateEditPlaylistDialogState createState() =>
      CreateEditPlaylistDialogState();
}

class CreateEditPlaylistDialogState extends State<CreateEditPlaylistDialog> {
  final titleController = TextEditingController();
  final groupController = TextEditingController();
  bool isLoading = false;
  List<String> groupList = ['Favorite'];

  Playlist? playlist;

  @override
  void initState() {
    super.initState();
    fetchGroupList();
    if (widget.playlistId != null) {
      loadPlaylist(widget.playlistId!);
    }
  }

  @override
  dispose() {
    super.dispose();
    titleController.dispose();
    groupController.dispose();
  }

  Future<void> fetchGroupList() async {
    final groups =
        await fetchCollectionGroupSummaryTitle(CollectionType.Playlist);

    if (!mounted) return;

    setState(() {
      groupList = cleanGroupTitles(['Favorite', ...groups]);
    });
  }

  Future<void> loadPlaylist(int playlistId) async {
    playlist = await getPlaylistById(playlistId);

    if (!mounted) return;
    if (playlist != null) {
      titleController.text = playlist!.name;
      groupController.text = playlist!.group;
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return UnavailableDialogOnBand(
      $close: widget.$close,
      child: NoShortcuts(
        ContentDialog(
          title: Column(
            children: [
              const SizedBox(height: 8),
              Text(
                widget.playlistId != null
                    ? S.of(context).editPlaylist
                    : S.of(context).createPlaylist,
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 16),
              InfoLabel(
                label: S.of(context).title,
                child: TextBox(
                  controller: titleController,
                  enabled: !isLoading,
                ),
              ),
              const SizedBox(height: 16),
              InfoLabel(
                label: S.of(context).group,
                child: AutoSuggestBox<String>(
                  controller: groupController,
                  items: groupList.map<AutoSuggestBoxItem<String>>((e) {
                    return AutoSuggestBoxItem<String>(
                      value: e,
                      label: e,
                    );
                  }).toList(),
                  placeholder: S.of(context).selectAGroup,
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
          actions: [
            ResponsiveDialogActions(
              FilledButton(
                onPressed: isLoading
                    ? null
                    : () async {
                        setState(() {
                          isLoading = true;
                        });

                        Playlist? response;
                        if (widget.playlistId != null) {
                          response = await updatePlaylist(
                            widget.playlistId!,
                            titleController.text,
                            groupController.text,
                          );
                        } else {
                          response = await createPlaylist(
                            titleController.text,
                            groupController.text,
                          );
                        }

                        CollectionCache().clearType(CollectionType.Playlist);

                        setState(() {
                          isLoading = false;
                        });

                        if (!context.mounted) return;
                        widget.$close(response);
                      },
                child: Text(
                  widget.playlistId != null
                      ? S.of(context).save
                      : S.of(context).create,
                ),
              ),
              Button(
                onPressed: isLoading ? null : () => widget.$close(null),
                child: Text(S.of(context).cancel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
