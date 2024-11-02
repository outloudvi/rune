import 'package:fluent_ui/fluent_ui.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../utils/router/navigation.dart';

void showCoverArtWall(BuildContext context) {
  final path = ModalRoute.of(context)?.settings.name;
  if (path == "/cover_wall") {
    if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  } else {
    $push(context, "/cover_wall");
  }
}

class CoverWallButton extends StatelessWidget {
  final List<Shadow>? shadows;

  const CoverWallButton({
    super.key,
    required this.shadows,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () => showCoverArtWall(context),
      icon: Icon(
        Symbols.photo_frame,
        shadows: shadows,
      ),
    );
  }
}
