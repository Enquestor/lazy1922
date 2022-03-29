import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lazy1922/models/place.dart';
import 'package:lazy1922/models/record.dart';
import 'package:lazy1922/models/record_action.dart';
import 'package:lazy1922/providers/is_place_mode_provider.dart';
import 'package:lazy1922/providers/places_provider.dart';
import 'package:lazy1922/providers/records_provider.dart';
import 'package:lazy1922/utils.dart';
import 'package:lazy1922/widgets/dialog_list_tile.dart';
import 'package:lazy1922/widgets/edit_place_dialog.dart';

final _reversedRecordsWithDatesProvider = Provider<List>((ref) {
  final reversedRecords = ref.watch(recordsProvider).reversed.toList();
  if (reversedRecords.isEmpty) {
    return [];
  }
  final reversedRecordsWithDates = [];
  DateTime? previousDate = date(reversedRecords.first.time);
  for (final record in reversedRecords) {
    final currentDate = date(record.time);
    if (currentDate != previousDate) {
      reversedRecordsWithDates.add(previousDate);
      previousDate = currentDate;
    }
    reversedRecordsWithDates.add(record);
  }
  reversedRecordsWithDates.add(date(reversedRecords.last.time));
  return reversedRecordsWithDates;
});

class MessagesPage extends ConsumerWidget {
  const MessagesPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reversedRecordsWithDates = ref.watch(_reversedRecordsWithDatesProvider).toList();
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      reverse: true,
      itemCount: reversedRecordsWithDates.length,
      itemBuilder: (context, index) {
        final item = reversedRecordsWithDates[index];
        if (item is DateTime) {
          return _buildDate(context, item);
        } else if (item is Record) {
          return _buildRecord(context, ref, item);
        } else {
          return const SizedBox();
        }
      },
    );
  }

  Widget _buildDate(BuildContext context, DateTime date) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 8),
          child: Text(
            DateFormat('EEEE, MMMM d').format(date),
            style: Theme.of(context).textTheme.caption,
          ),
        ),
      ],
    );
  }

  Widget _buildRecord(BuildContext context, WidgetRef ref, Record record) {
    final isPlaceMode = ref.watch(isPlaceModeProvider);
    final placeMap = ref.watch(placesMapProvider);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 4, right: 8),
            child: Text(
              DateFormat('h:mm a').format(record.time),
              style: Theme.of(context).textTheme.caption,
            ),
          ),
          Flexible(
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.75,
              child: Container(
                decoration: record.isLocationAvailable
                    ? BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: Theme.of(context).colorScheme.primary,
                      )
                    : BoxDecoration(
                        border: Border.all(color: Theme.of(context).colorScheme.primary),
                        borderRadius: BorderRadius.circular(20),
                        color: Colors.transparent,
                      ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 12, right: 12, bottom: 10, top: 8),
                      child: Text(
                        isPlaceMode && placeMap.containsKey(record.code) ? placeMap[record.code]!.name : record.message,
                        style: Theme.of(context).textTheme.bodyText2!.copyWith(fontSize: 16, color: record.isLocationAvailable ? Colors.white : null),
                      ),
                    ),
                    onLongPress: () => _onRecordLongPress(context, ref, record),
                  ),
                ),
                clipBehavior: Clip.antiAliasWithSaveLayer,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _onRecordLongPress(BuildContext context, WidgetRef ref, Record record) async {
    final placeMap = ref.read(placesMapProvider);
    List<DialogListTile> children = [
      DialogListTile(
        title: Text(
          'delete_message'.tr(),
          style: const TextStyle(color: Colors.red),
        ),
        onTap: () => Navigator.of(context).pop(RecordAction.delete),
      ),
    ];
    if (record.isLocationAvailable && !placeMap.containsKey(record.code)) {
      children = [
        DialogListTile(
          title: Text('add_to_favorites'.tr()),
          onTap: () => Navigator.of(context).pop(RecordAction.addToFavorites),
        ),
        ...children,
      ];
    }

    final selection = await showDialog<RecordAction>(
      context: context,
      builder: (context) => SimpleDialog(
        clipBehavior: Clip.antiAliasWithSaveLayer,
        children: children,
      ),
    );

    switch (selection) {
      case RecordAction.addToFavorites:
        showDialog(
          context: context,
          builder: (context) => EditPlaceDialog(
            isAdd: true,
            place: Place.fromRecord(record, ''),
            onConfirm: (place) {
              final placeNotifier = ref.read(placesProvider.notifier);
              placeNotifier.add(place);
            },
          ),
        );
        break;
      case RecordAction.delete:
        final recordsNotifier = ref.read(recordsProvider.notifier);
        recordsNotifier.removeRecord(record);
        break;
      case null:
        break;
    }
  }
}
