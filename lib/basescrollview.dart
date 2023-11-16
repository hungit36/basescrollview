import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class BaseScrollView extends StatefulWidget {
  const BaseScrollView({
    super.key,
    required this.child,
    this.onRefresh,
    this.onScrollStart,
    this.onLoadMore,
    this.onScrollUpdate,
    required this.isLoading,
    this.indicatorColor = Colors.black54, 
    this.isEnableRefreshIndicator = true,
  });
  ///enable or disable the refresh indicator when pull to refresh
  final bool isEnableRefreshIndicator;
  ///color the indicator
  final Color indicatorColor;
  final bool isLoading;
  final Widget child;
  final VoidCallback? onScrollStart;
  final VoidCallback? onRefresh;
  final VoidCallback? onLoadMore;
  final void Function(ScrollDirection, double)? onScrollUpdate;

  @override
  State<BaseScrollView> createState() => _BaseScrollViewtate();
}

class _BaseScrollViewtate extends State<BaseScrollView> {
  bool _isUserScroll = false;
  double _oldOffset = 0;
  ScrollDirection _direction = ScrollDirection.idle;
  bool _isScrollToTop = false;

  _onUpdateScroll(ScrollMetrics metrics) {
    _direction = _oldOffset < metrics.pixels ? ScrollDirection.forward : ScrollDirection.reverse;
    widget.onScrollUpdate?.call(_direction, _oldOffset);
    _oldOffset = metrics.pixels;
    if (!widget.isEnableRefreshIndicator && metrics.pixels < -65) {
      _isScrollToTop = true;
    }
  }

  _onEndScroll(ScrollMetrics metrics) {
    if (_isUserScroll == false) return;
    _isUserScroll = false;
    widget.onScrollUpdate?.call(_direction, metrics.pixels);
    if (metrics.atEdge) {
      bool isTop = _direction == ScrollDirection.reverse;
      if (!isTop) {
        widget.onLoadMore?.call();
      } else if (_isScrollToTop && !widget.isEnableRefreshIndicator) {
        _isScrollToTop = false;
        widget.onRefresh?.call();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MyLoadingView(
      isLoading: widget.isLoading,
      indicatorColor: widget.indicatorColor,
      child: widget.isEnableRefreshIndicator ? RefreshIndicator(
        color: widget.indicatorColor,
        onRefresh: () async {
          widget.onRefresh?.call();
        },
        notificationPredicate: (notification) {
          if (notification is ScrollStartNotification) {
            widget.onScrollStart?.call();
          } else if (notification is ScrollUpdateNotification && notification.dragDetails != null) {
            _isUserScroll = true;
              _onUpdateScroll(notification.metrics);
          } else if (notification is ScrollEndNotification) {
            _onEndScroll(notification.metrics);
          }
          return true;
        },
        displacement: 50,
        child: widget.child,
      ) : NotificationListener(
        onNotification: (scrollNotification) {
          if (scrollNotification is ScrollStartNotification) {
            widget.onScrollStart?.call();
          } else if (scrollNotification is ScrollUpdateNotification && scrollNotification.dragDetails != null) {
            _isUserScroll = true;
            _onUpdateScroll(scrollNotification.metrics);
          } else if (scrollNotification is ScrollEndNotification) {
            _onEndScroll(scrollNotification.metrics);
          }
          return true;
        },
        child: widget.child,
      ),
    );
  }

}

class MyLoadingView extends StatelessWidget {
  final Color indicatorColor;
  final bool isLoading;
  final bool? showLoadingIcon;
  final Widget child;

  const MyLoadingView({
    super.key,
    required this.isLoading,
    this.showLoadingIcon = true,
    required this.child,
    this.indicatorColor = Colors.black54,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.7)),
              width: double.infinity,
              height: double.infinity,
              child: Center(
                child: (showLoadingIcon ?? false) ? SizedBox(width: 24, height: 24,child: CircularProgressIndicator(color: indicatorColor,)) : const SizedBox(width: 24, height: 24),
              ),
            ),
          ),
      ],
    );
  }
}
