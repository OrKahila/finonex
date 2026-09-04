import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/feed/feed_connection_bloc.dart';
import '../blocs/feed/feed_event.dart';
import '../blocs/price/price_bloc.dart';
import '../blocs/price/price_event.dart';

/// Translates OS lifecycle transitions into bloc events.
///
/// Only `pause` and `resume` are wired up, and that is deliberate. The full
/// sequence on the way out is resumed -> inactive -> hidden -> paused, and
/// `inactive` alone fires for things the user has not really left: the app
/// switcher, Control Centre, an incoming call, a permission dialog. Dropping
/// the feed on `inactive` would mean a reconnect every time someone glanced at
/// their notifications.
///
/// Both handlers are idempotent - the blocs ignore a transition they are
/// already in - so a `resume` that follows a bare `inactive` (where nothing was
/// ever torn down) costs nothing.
class AppLifecycleBridge extends StatefulWidget {
  const AppLifecycleBridge({required this.child, super.key});

  final Widget child;

  @override
  State<AppLifecycleBridge> createState() => _AppLifecycleBridgeState();
}

class _AppLifecycleBridgeState extends State<AppLifecycleBridge> {
  late final AppLifecycleListener _listener;

  @override
  void initState() {
    super.initState();
    _listener = AppLifecycleListener(
      onPause: _onBackground,
      onResume: _onForeground,
    );
  }

  @override
  void dispose() {
    _listener.dispose();
    super.dispose();
  }

  void _onBackground() {
    if (!mounted) return;
    context.read<FeedConnectionBloc>().add(const FeedEvent.appBackgrounded());
  }

  void _onForeground() {
    if (!mounted) return;
    context.read<FeedConnectionBloc>().add(const FeedEvent.appForegrounded());
    // Badge anything that went quiet while we were away on the very first
    // frame back, rather than up to a second later when the sweep next runs.
    context.read<PriceBloc>().add(const PriceEvent.stalenessChecked());
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
