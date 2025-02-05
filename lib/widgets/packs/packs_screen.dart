/*This file is part of Medito App.

Medito App is free software: you can redistribute it and/or modify
it under the terms of the Affero GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
(at your option) any later version.

Medito App is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
Affero GNU General Public License for more details.

You should have received a copy of the Affero GNU General Public License
along with Medito App. If not, see <https://www.gnu.org/licenses/>.*/

import 'package:Medito/network/api_response.dart';
import 'package:Medito/network/packs/packs_bloc.dart';
import 'package:Medito/network/packs/packs_response.dart';
import 'package:Medito/utils/navigation.dart';
import 'package:Medito/utils/utils.dart';
import 'package:Medito/widgets/packs/announcement_banner_widget.dart';
import 'package:Medito/widgets/downloads/download_tile_widget.dart';
import 'package:Medito/widgets/packs/error_widget.dart';
import 'package:Medito/widgets/packs/medito_logo_widget.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:package_info/package_info.dart';
import 'package:Medito/tracking/tracking.dart';
import 'package:Medito/utils/colors.dart';
import 'package:Medito/utils/stats_utils.dart';
import 'package:Medito/widgets/column_builder.dart';
import 'package:Medito/widgets/streak_widgets/streak_page.dart';
import 'package:Medito/widgets/streak_tile_widget.dart';

class PackListWidget extends StatefulWidget {
  PackListWidget({Key key}) : super(key: key);

  @override
  PackListWidgetState createState() {
    return PackListWidgetState();
  }
}

class PackListWidgetState extends State<PackListWidget> {
  var _streak;
  bool _dialogShown = false;
  PacksBloc _packsBloc;

  @override
  void initState() {
    Tracking.changeScreenName(Tracking.HOME);

    super.initState();
    _packsBloc = PacksBloc();
    _streak = getCurrentStreak();
  }

  @override
  Widget build(BuildContext context) {
    _trackingDialog(context);
    return Container(
      color: MeditoColors.darkMoon,
      child: SafeArea(
        bottom: false,
        child: _streamBuilderWidget(),
      ),
    );
  }

  Widget _streamBuilderWidget() {
    return RefreshIndicator(
      displacement: 80,
      color: MeditoColors.walterWhite,
      backgroundColor: MeditoColors.moonlight,
      onRefresh: () => _packsBloc.fetchPacksList(true),
      child: StreamBuilder<ApiResponse<List<PacksData>>>(
          stream: _packsBloc.packListStream,
          initialData: ApiResponse.loading(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              switch (snapshot.data.status) {
                case Status.LOADING:
                  return getLoadingWidget();
                case Status.COMPLETED:
                  return _getScrollWidget(snapshot.data.body);
                case Status.ERROR:
                  return ErrorPacksWidget(
                    onPressed: () => _packsBloc.fetchPacksList(true),
                    widget: _getMeditoLogoWidget(),
                  );
                default:
                  return Container();
              }
            } else {
              return Container();
            }
          }),
    );
  }

  Widget _getScrollWidget(List<PacksData> data) {
    return SingleChildScrollView(
      primary: true,
      child: Column(
        children: <Widget>[
          _getMeditoLogoWidget(),
          AnnouncementBanner(),
          _getTwoColumns(data)
        ],
      ),
    );
  }

  Future<void> _trackingDialog(BuildContext context) async {
    await getTrackingAnswered().then((answered) async {
      if (!answered && !_dialogShown) showConsentDialog(context);
      _dialogShown = true;
    });
  }

  Widget _getTwoColumns(List<PacksData> data) {
    var firstCol = data.getRange(0, data.length ~/ 2).toList();
    var secondCol = data.getRange(data.length ~/ 2, data.length).toList();

    return Padding(
      padding: const EdgeInsets.only(left: 8, right: 8, bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.start,
        children: <Widget>[
          //left column
          SizedBox(
            width: _getColumnWidth(),
            child: ColumnBuilder(
                itemCount: firstCol.length,
                itemBuilder: (BuildContext context, int index) {
                  var tile = firstCol[index];
                  return _getTile(tile);
                }),
          ),
          //right column
          SizedBox(
            width: _getColumnWidth(),
            child: ColumnBuilder(
                itemCount: secondCol.length + 1,
                itemBuilder: (BuildContext context, int index) {
                  if (index == secondCol.length) {
                    return StreakTileWidget(_streak, 'Current Streak',
                        optionalText: UnitType.day, onClick: _onStreakTap);
                  } else if (index == secondCol.length - 1) {
                    return DownloadTileWidget();
                  } else {
                    try {
                      var tile = secondCol[index];
                      return _getTile(tile);
                    } catch (e) {
                      return Container();
                    }
                  }
                }),
          ),
        ],
      ),
    );
  }

  //todo horrible hack, but necessary because autosizetext cannot be passed unbound constraints
  //see here https://stackoverflow.com/questions/53882591/autoresize-text-to-fit-in-container-vertically
  double _getColumnWidth() => MediaQuery.of(context).size.width / 2 - 8;

  Widget _getTile(PacksData item) {
    return GestureDetector(
      onTap: () => NavigationFactory.navigate(
          context, NavigationFactory.getScreenFromItemType(item.fileType),
          id: item.id),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            color: parseColor(item.colorPrimary),
          ),
          child: Padding(
            padding: const EdgeInsets.only(
                top: 16.0, bottom: 16, left: 10, right: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Container(height: 8),
                SizedBox(height: 80, child: getNetworkImageWidget(item.cover)),
                Container(height: 16),
                SizedBox(
                  width: _getColumnWidth() - 48, //todo horrible hack
                  child: AutoSizeText(item.title,
                      maxLines: 2,
                      textAlign: TextAlign.center,
                      wrapWords: false,
                      style: Theme.of(context).textTheme.headline6.copyWith(
                          color: parseColor(item.colorSecondary),
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.1,
                          height: 1.3)),
                ),
                Container(height: item.subtitle != '' ? 4 : 0),
                item.subtitle.isNotEmptyAndNotNull()
                    ? SizedBox(
                        width: _getColumnWidth() - 48, //todo horrible hack
                        child: Opacity(
                          opacity: .7,
                          child: AutoSizeText(item.subtitle,
                              maxLines: 2,
                              textAlign: TextAlign.center,
                              wrapWords: false,
                              style: Theme.of(context)
                                  .textTheme
                                  .subtitle1
                                  .copyWith(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: 0.1,
                                      color: parseColor(item.colorSecondary))),
                        ),
                      )
                    : Container(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onStreakTap() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => StreakWidget()),
    ).then((value) {
      setState(() {
        _streak = getCurrentStreak();
      });
    });
  }

  Widget _getMeditoLogoWidget() {
    return MeditoLogo(
      onDoubleTap: () => _showVersionPopUp(),
      onLongPress: () => _packsBloc.fetchPacksList(true),
    );
  }

  Future<void> _showVersionPopUp() async {
    var packageInfo = await PackageInfo.fromPlatform();

    var version = packageInfo.version;
    var buildNumber = packageInfo.buildNumber;

    final snackBar = SnackBar(
        content: Text(
          'Version: $version - Build Number: $buildNumber',
          style: TextStyle(color: MeditoColors.lightTextColor),
        ),
        backgroundColor: MeditoColors.midnight);

    // Find the Scaffold in the Widget tree and use it to show a SnackBar!
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  @override
  void dispose() {
    _packsBloc.dispose();
    super.dispose();
  }

  ///  This is for the skeleton screen
  Widget getLoadingWidget() {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          _getMeditoLogoWidget(),
          Container(height: 8),
          getBlankTile(MeditoColors.moonlight),
          getBlankTile(MeditoColors.moonlight),
          getBlankTile(MeditoColors.moonlight),
          getBlankTile(MeditoColors.moonlight),
          getBlankTile(MeditoColors.moonlight),
          getBlankTile(MeditoColors.moonlight),
          getBlankTile(MeditoColors.moonlight),
          getBlankTile(MeditoColors.moonlight),
        ],
      ),
    );
  }

  Widget getBlankTile(Color color) {
    return Padding(
      padding: const EdgeInsets.only(right: 16.0, bottom: 16.0, left: 16.0),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(12)),
                color: color,
              ),
              height: 100,
            ),
          ),
        ],
      ),
    );
  }

  /// ////////

}
