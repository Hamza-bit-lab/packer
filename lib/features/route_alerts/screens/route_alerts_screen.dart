import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/api/route_alert_repository.dart';
import '../../../core/models/route_alert.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';

class RouteAlertsScreen extends StatefulWidget {
  const RouteAlertsScreen({super.key});

  @override
  State<RouteAlertsScreen> createState() => _RouteAlertsScreenState();
}

class _RouteAlertsScreenState extends State<RouteAlertsScreen> {
  List<RouteAlert> _alerts = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _load();
  }

  RouteAlertRepository get _repository =>
      RouteAlertRepository(context.read<AuthProvider>().client);

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      _alerts = await _repository.fetchMine();
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _errorMessage =
            'Could not load your route alerts. Pull down to try again.',
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _addAlert() async {
    final result = await showDialog<_NewAlert>(
      context: context,
      builder: (context) => const _AddAlertDialog(),
    );
    if (result == null) return;

    try {
      final created = await _repository.create(
        watchType: result.watchType,
        fromCity: result.fromCity,
        toCity: result.toCity,
      );
      if (!mounted) return;
      setState(() => _alerts = [created, ..._alerts]);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('ApiException: ', '')),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _delete(RouteAlert alert) async {
    setState(() => _alerts = _alerts.where((a) => a.id != alert.id).toList());
    try {
      await _repository.delete(alert.id);
    } catch (_) {
      if (mounted) setState(() => _alerts = [..._alerts, alert]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Route Alerts'),
        actions: [
          IconButton(onPressed: _addAlert, icon: const Icon(Icons.add_rounded)),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (_errorMessage != null && _alerts.isEmpty) {
      return _MessageView(
        message: _errorMessage!,
        onRetry: _load,
        onAdd: _addAlert,
      );
    }

    if (_alerts.isEmpty) {
      return _MessageView(
        message:
            "Get notified when a new trip or item is posted on a route you care about.",
        onRetry: _load,
        onAdd: _addAlert,
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.primary,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        itemCount: _alerts.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final alert = _alerts[index];
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadii.tile),
              border: Border.all(color: AppColors.border),
              boxShadow: AppShadows.subtle,
            ),
            child: Row(
              children: [
                Icon(
                  alert.watchType == RouteAlertWatchType.travelers
                      ? Icons.flight_takeoff_rounded
                      : Icons.inventory_2_outlined,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${alert.fromCity} → ${alert.toCity}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14.5,
                        ),
                      ),
                      Text(
                        alert.watchType == RouteAlertWatchType.travelers
                            ? 'New travelers'
                            : 'New items',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => _delete(alert),
                  icon: Icon(
                    Icons.delete_outline_rounded,
                    color: AppColors.error,
                    size: 20,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MessageView extends StatelessWidget {
  const _MessageView({
    required this.message,
    required this.onRetry,
    required this.onAdd,
  });

  final String message;
  final Future<void> Function() onRetry;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.bookmark_border_rounded,
              color: AppColors.textSecondary,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onAdd,
              child: const Text('Add a route alert'),
            ),
          ],
        ),
      ),
    );
  }
}

class _NewAlert {
  _NewAlert({
    required this.watchType,
    required this.fromCity,
    required this.toCity,
  });

  final RouteAlertWatchType watchType;
  final String fromCity;
  final String toCity;
}

class _AddAlertDialog extends StatefulWidget {
  const _AddAlertDialog();

  @override
  State<_AddAlertDialog> createState() => _AddAlertDialogState();
}

class _AddAlertDialogState extends State<_AddAlertDialog> {
  final _fromController = TextEditingController();
  final _toController = TextEditingController();
  RouteAlertWatchType _watchType = RouteAlertWatchType.travelers;

  @override
  void dispose() {
    _fromController.dispose();
    _toController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New route alert'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SegmentedButton<RouteAlertWatchType>(
            segments: const [
              ButtonSegment(
                value: RouteAlertWatchType.travelers,
                label: Text('Travelers'),
              ),
              ButtonSegment(
                value: RouteAlertWatchType.goods,
                label: Text('Items'),
              ),
            ],
            selected: {_watchType},
            onSelectionChanged: (selection) =>
                setState(() => _watchType = selection.first),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _fromController,
            decoration: const InputDecoration(hintText: 'From city'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _toController,
            decoration: const InputDecoration(hintText: 'To city'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            if (_fromController.text.trim().isEmpty ||
                _toController.text.trim().isEmpty)
              return;
            Navigator.of(context).pop(
              _NewAlert(
                watchType: _watchType,
                fromCity: _fromController.text.trim(),
                toCity: _toController.text.trim(),
              ),
            );
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
