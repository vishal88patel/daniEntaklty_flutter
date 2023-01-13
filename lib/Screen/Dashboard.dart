import 'dart:async';
import 'dart:io';

import 'package:bottom_bar/bottom_bar.dart';
import 'package:eshop/Helper/PushNotificationService.dart';
import 'package:eshop/Helper/Session.dart';
import 'package:eshop/Helper/SqliteData.dart';
import 'package:eshop/Helper/String.dart';
import 'package:eshop/Model/Section_Model.dart';
import 'package:eshop/Provider/HomeProvider.dart';
import 'package:eshop/Provider/UserProvider.dart';
import 'package:eshop/Screen/Cart.dart';
import 'package:eshop/Screen/Login.dart';
import 'package:eshop/Screen/MyProfile.dart';
import 'package:eshop/ui/styles/Color.dart';
import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:package_info/package_info.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:version/version.dart';

import '../Provider/SettingProvider.dart';
import '../ui/styles/DesignConfig.dart';
import 'HomePage.dart';
import 'Manage_Address.dart';
import 'NotificationLIst.dart';
import 'ProductList.dart';
import 'Product_Detail.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<Dashboard>
    with SingleTickerProviderStateMixin {
  int _selBottom = 0;

  final PageController _pageController = PageController();
  bool _isNetworkAvail = true;
  var db = DatabaseHelper();
  late AnimationController navigationContainerAnimationController =
      AnimationController(
    vsync: this, // the SingleTickerProviderStateMixin
    duration: const Duration(milliseconds: 500),
  );
  FirebaseDynamicLinks dynamicLinks = FirebaseDynamicLinks.instance;

  @override
  void initState() {
    super.initState();
    callApi();
    initDynamicLinks();
    db.getTotalCartCount(context);
    final pushNotificationService = PushNotificationService(
        context: context, pageController: _pageController);
    pushNotificationService.initialise();

    Future.delayed(Duration.zero, () async {
      SettingProvider settingsProvider =
          Provider.of<SettingProvider>(context, listen: false);
      CUR_USERID = await settingsProvider.getPrefrence(ID) ?? '';
      context
          .read<HomeProvider>()
          .setAnimationController(navigationContainerAnimationController);
    });
  }

  Future<void> callApi() async {
    UserProvider user = Provider.of<UserProvider>(context, listen: false);
    SettingProvider setting =
        Provider.of<SettingProvider>(context, listen: false);

    user.setUserId(setting.userId);
    user.setMobile(setting.mobile);
    user.setName(setting.userName);
    user.setEmail(setting.email);
    user.setProfilePic(setting.profileUrl);

    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      getSetting();
    } else {
      if (mounted) {
        setState(() {
          _isNetworkAvail = false;
        });
      }
    }

    return;
  }

  void getSetting() {
    try {
      CUR_USERID = context.read<SettingProvider>().userId;

      Map parameter = {};
      if (CUR_USERID != null) parameter = {USER_ID: CUR_USERID};

      apiBaseHelper.postAPICall(getSettingApi, parameter).then((getdata) async {
        bool error = getdata["error"];
        String? msg = getdata["message"];

        if (!error) {
          var data = getdata["data"]["system_settings"][0];
          SUPPORTED_LOCALES = data["supported_locals"];
          if (data.toString().contains(MAINTAINANCE_MODE)) {
            Is_APP_IN_MAINTANCE = data[MAINTAINANCE_MODE];
          }
          if (Is_APP_IN_MAINTANCE != "1") {
            // getSlider();
            // getCat();
            // getSection();
            // getOfferImages();
            //
            // proIds = (await db.getMostLike())!;
            // getMostLikePro();
            // proIds1 = (await db.getMostFav())!;
            // getMostFavPro();
          }

          if (data.toString().contains(MAINTAINANCE_MESSAGE)) {
            IS_APP_MAINTENANCE_MESSAGE = data[MAINTAINANCE_MESSAGE];
          }

          cartBtnList = data["cart_btn_on_list"] == "1" ? true : false;
          refer = data["is_refer_earn_on"] == "1" ? true : false;
          CUR_CURRENCY = data["currency"];
          RETURN_DAYS = data['max_product_return_days'];
          MAX_ITEMS = data["max_items_cart"];
          MIN_AMT = data['min_amount'];
          CUR_DEL_CHR = data['delivery_charge'];
          String? isVerion = data['is_version_system_on'];
          extendImg = data["expand_product_images"] == "1" ? true : false;
          String? del = data["area_wise_delivery_charge"];
          MIN_ALLOW_CART_AMT = data[MIN_CART_AMT];
          IS_LOCAL_PICKUP = data[LOCAL_PICKUP];
          ADMIN_ADDRESS = data[ADDRESS];
          ADMIN_LAT = data[LATITUDE];
          ADMIN_LONG = data[LONGITUDE];
          ADMIN_MOB = data[SUPPORT_NUM];
          print("local pickup****${IS_LOCAL_PICKUP}");

          ALLOW_ATT_MEDIA = data[ALLOW_ATTACH];

          if (data.toString().contains(UPLOAD_LIMIT)) {
            UP_MEDIA_LIMIT = data[UPLOAD_LIMIT];
          }

          if (Is_APP_IN_MAINTANCE == "1") {
            appMaintenanceDialog(context);
          }

          if (del == "0") {
            ISFLAT_DEL = true;
          } else {
            ISFLAT_DEL = false;
          }

          if (CUR_USERID != null) {
            REFER_CODE = getdata['data']['user_data'][0]['referral_code'];

            context
                .read<UserProvider>()
                .setPincode(getdata["data"]["user_data"][0][PINCODE]);

            if (REFER_CODE == null || REFER_CODE == '' || REFER_CODE!.isEmpty) {
              // generateReferral();
            }

            context.read<UserProvider>().setCartCount(
                getdata["data"]["user_data"][0]["cart_total_items"].toString());
            context
                .read<UserProvider>()
                .setBalance(getdata["data"]["user_data"][0]["balance"]);
            if (Is_APP_IN_MAINTANCE != "1") {
              // _getFav();
              // _getCart("0");
            }
          } else {
            if (Is_APP_IN_MAINTANCE != "1") {
              // _getOffFav();
              // _getOffCart();
            }
          }

          Map<String, dynamic> tempData = getdata["data"];
          if (tempData.containsKey(TAG)) {
            tagList = List<String>.from(getdata["data"][TAG]);
          }

          if (isVerion == "1") {
            String? verionAnd = data['current_version'];
            String? verionIOS = data['current_version_ios'];

            PackageInfo packageInfo = await PackageInfo.fromPlatform();

            String version = packageInfo.version;

            final Version currentVersion = Version.parse(version);
            final Version latestVersionAnd = Version.parse(verionAnd);
            print("latest version****$latestVersionAnd******$currentVersion");
            final Version latestVersionIos = Version.parse(verionIOS);

            if ((Platform.isAndroid && latestVersionAnd > currentVersion) ||
                (Platform.isIOS && latestVersionIos > currentVersion)) {
              // updateDailog();
            }
          }
        } else {
          setSnackbar(msg!, context);
        }
      }, onError: (error) {
        setSnackbar(error.toString(), context);
      });
    } on FormatException catch (e) {
      setSnackbar(e.message, context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_selBottom != 0) {
          _pageController.animateToPage(0,
              duration: const Duration(milliseconds: 1000),
              curve: Curves.easeInOut);
          return false;
        }
        return true;
      },
      child: Scaffold(
        extendBody: true,
        backgroundColor: Theme.of(context).colorScheme.lightWhite,
        appBar: _selBottom == 0 ? _getAppBar() : null,
        body: PageView(
          controller: _pageController,
          children: const [
            // HomePage(),
            ProductList(
              name: "Men's Fashion",
              id: "111",
              tag: false,
              fromSeller: false,
            ),

            const ManageAddress(
              home: true,
            ),
            // AllCategory(),
            // Sale(),
            Cart(
              fromBottom: true,
            ),
            MyProfile()
          ],
          onPageChanged: (index) {
            setState(() {
              if (!context
                  .read<HomeProvider>()
                  .animationController
                  .isAnimating) {
                context.read<HomeProvider>().animationController.reverse();
                context.read<HomeProvider>().showBars(true);
              }
              _selBottom = index;
              if (index == 3) {
                cartTotalClear();
              }
            });
          },
        ),
        bottomNavigationBar: _getBottomBar(),
      ),
    );
  }

  void initDynamicLinks() async {
    dynamicLinks.onLink.listen((dynamicLinkData) {
      final Uri deepLink = dynamicLinkData.link;

      if (deepLink.queryParameters.isNotEmpty) {
        int index = int.parse(deepLink.queryParameters['index']!);

        int secPos = int.parse(deepLink.queryParameters['secPos']!);

        String? id = deepLink.queryParameters['id'];

        String? list = deepLink.queryParameters['list'];

        getProduct(id!, index, secPos, list == "true" ? true : false);
      }
    }).onError((e) {
      print(e.message);
    });

    final PendingDynamicLinkData? data =
        await FirebaseDynamicLinks.instance.getInitialLink();
    final Uri? deepLink = data?.link;
    if (deepLink != null) {
      if (deepLink.queryParameters.isNotEmpty) {
        int index = int.parse(deepLink.queryParameters['index']!);

        int secPos = int.parse(deepLink.queryParameters['secPos']!);

        String? id = deepLink.queryParameters['id'];

        getProduct(id!, index, secPos, true);
      }
    }
  }

  Future<void> getProduct(String id, int index, int secPos, bool list) async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        var parameter = {
          ID: id,
        };

        apiBaseHelper.postAPICall(getProductApi, parameter).then((getdata) {
          bool error = getdata["error"];
          String msg = getdata["message"];
          if (!error) {
            var data = getdata["data"];

            List<Product> items = [];

            items =
                (data as List).map((data) => Product.fromJson(data)).toList();
            currentHero = homeHero;
            Navigator.of(context).push(CupertinoPageRoute(
                builder: (context) => ProductDetail(
                      index: list ? int.parse(id) : index,
                      model: list
                          ? items[0]
                          : sectionList[secPos].productList![index],
                      secPos: secPos,
                      list: list,
                    )));
          } else {
            if (msg != "Products Not Found !") setSnackbar(msg, context);
          }
        }, onError: (error) {
          setSnackbar(error.toString(), context);
        });
      } on TimeoutException catch (_) {
        setSnackbar(getTranslated(context, 'somethingMSg')!, context);
      }
    } else {
      {
        if (mounted) {
          setState(() {
            setSnackbar(getTranslated(context, 'NO_INTERNET_DISC')!, context);
          });
        }
      }
    }
  }

  AppBar _getAppBar() {
    String? title;
    if (_selBottom == 1) {
      title = getTranslated(context, 'CATEGORY');
    } else if (_selBottom == 2) {
      title = getTranslated(context, 'OFFER');
    } else if (_selBottom == 3) {
      title = getTranslated(context, 'MYBAG');
    } else if (_selBottom == 4) {
      title = getTranslated(context, 'PROFILE');
    }

    return AppBar(
      elevation: 0,
      centerTitle: false,
      titleSpacing: -25,
      title: _selBottom == 0
          ? /*SvgPicture.asset(
              'assets/images/titleicon.svg',
              height: 35,
              color: colors.primary,
            )*/
          Padding(
              padding: const EdgeInsets.only(top: 8.0, left: 40),
              child: Image.asset(
                'assets/images/mynewlogo.png',
                width: 100,
                height: 50,
                color: Colors.black,
              ),
            )
          : Text(
              title!,
              style: const TextStyle(
                  color: colors.primary, fontWeight: FontWeight.normal),
            ),
      actions: <Widget>[
        Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: InkWell(
            child: SvgPicture.asset(
              "assets/images/ic_web.svg",
              height: 25,
              width: 25,
            ),
            onTap: () {
              launchWeb();
            },
          ),
        ),
        SizedBox(width: 17,),

        Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: InkWell(
            child: SvgPicture.asset(
              "assets/images/instagramImage.svg",
              height: 25,
              width: 25,
            ),
            onTap: () {
              openInstagram();
            },
          ),
        ),
        SizedBox(width: 17,),

        Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: InkWell(
            child: SvgPicture.asset(
              "assets/images/facebookImage.svg",
              height: 30,
              width: 30,
            ),
            onTap: () {
              openFaceBook();
            },
          ),
        ),
        SizedBox(width: 15,),

        Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: InkWell(
            child: SvgPicture.asset(
              "assets/images/whatsappImage.svg",
              height: 26,
              width: 26,
            ),
            onTap: () {
              openwhatsapp();
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: IconButton(
            icon: SvgPicture.asset(
              "${imagePath}desel_notification.svg",
              color: colors.primary,
            ),
            onPressed: () {
              CUR_USERID != null
                  ? Navigator.push<bool>(
                      context,
                      CupertinoPageRoute(
                        builder: (context) => const NotificationList(),
                      )).then((value) {
                      if (value != null && value) {
                        _pageController.jumpToPage(1);
                      }
                    })
                  : Navigator.push(
                      context,
                      CupertinoPageRoute(
                        builder: (context) => const Login(),
                      ));
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Selector<UserProvider, String>(
            builder: (context, data, child) {
              return IconButton(
                icon: Stack(
                  children: [
                    Center(
                        child: SvgPicture.asset(
                      "${imagePath}appbarCart.svg",
                      color: colors.primary,
                    )),
                    (data != "" && data.isNotEmpty && data != "0")
                        ? Positioned(
                            bottom: 20,
                            right: 0,
                            child: Container(
                                decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: colors.primary),
                                child: Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(3),
                                    child: Text(
                                      data,
                                      style: TextStyle(
                                          fontSize: 7,
                                          fontWeight: FontWeight.bold,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .white),
                                    ),
                                  ),
                                )),
                          )
                        : Container()
                  ],
                ),
                onPressed: () {
                  cartTotalClear();
                  Navigator.push(
                    context,
                    CupertinoPageRoute(
                      builder: (context) => const Cart(
                        fromBottom: false,
                      ),
                    ),
                  );
                },
              );
            },
            selector: (_, homeProvider) => homeProvider.curCartCount,
          ),
        ),
        SizedBox(
          width: 8,
        )
        /*IconButton(
          padding: const EdgeInsets.all(0),
          icon: SvgPicture.asset(
            "${imagePath}desel_fav.svg",
            color: colors.primary,
          ),
          onPressed: () {
            Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (context) => const Favorite(),
                ));
          },
        ),*/
      ],
      backgroundColor: Theme.of(context).colorScheme.lightWhite,
    );
  }

  Widget _getBottomBar() {
    return FadeTransition(
        opacity: Tween<double>(begin: 1.0, end: 0.0).animate(CurvedAnimation(
            parent: navigationContainerAnimationController,
            curve: Curves.easeInOut)),
        child: SlideTransition(
          position:
              Tween<Offset>(begin: Offset.zero, end: const Offset(0.0, 1.0))
                  .animate(CurvedAnimation(
                      parent: navigationContainerAnimationController,
                      curve: Curves.easeInOut)),
          child: Container(
            height: kBottomNavigationBarHeight,
            decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.white,
                borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20))),
            child: BottomBar(
              duration: const Duration(milliseconds: 1000),
              curve: Curves.easeInOut,
              selectedIndex: _selBottom,
              onTap: (int index) {
                _pageController.jumpToPage(index);
                setState(() => _selBottom = index);
              },
              items: <BottomBarItem>[
                BottomBarItem(
                  icon: _selBottom == 0
                      ? SvgPicture.asset(
                          "${imagePath}sel_home.svg",
                          color: colors.primary,
                        )
                      : SvgPicture.asset(
                          "${imagePath}desel_home.svg",
                          color: colors.primary,
                        ),
                  title: Text(getTranslated(context, 'HOME_LBL')!,
                      overflow: TextOverflow.ellipsis),
                  activeColor: colors.primary,
                ),
                BottomBarItem(
                    icon: _selBottom == 1
                        ? SvgPicture.asset(
                            "assets/images/location.svg",
                            color: colors.primary,
                          )
                        : SvgPicture.asset(
                            "assets/images/location.svg",
                            color: colors.primary,
                          ),
                    title: Text("Location"),
                    activeColor: colors.primary),
                // BottomBarItem(
                //   icon: _selBottom == 2
                //       ? SvgPicture.asset(
                //           "${imagePath}sale02.svg",
                //           color: colors.primary,
                //         )
                //       : SvgPicture.asset(
                //           "${imagePath}sale.svg",
                //           color: colors.primary,
                //         ),
                //   title: Text(getTranslated(context, 'SALE')!),
                //   activeColor: colors.primary,
                // ),
                BottomBarItem(
                  icon: Selector<UserProvider, String>(
                    builder: (context, data, child) {
                      return Stack(
                        children: [
                          _selBottom == 3
                              ? SvgPicture.asset(
                                  "${imagePath}cart01.svg",
                                  color: colors.primary,
                                )
                              : SvgPicture.asset(
                                  "${imagePath}cart.svg",
                                  color: colors.primary,
                                ),
                          (data.isNotEmpty && data != "0")
                              ? Positioned.directional(
                                  end: 0,
                                  textDirection: Directionality.of(context),
                                  top: 0,
                                  child: Container(
                                      decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: colors.primary),
                                      child: Center(
                                        child: Padding(
                                          padding: const EdgeInsets.all(3),
                                          child: Text(
                                            data,
                                            style: TextStyle(
                                                fontSize: 7,
                                                fontWeight: FontWeight.bold,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .white),
                                          ),
                                        ),
                                      )),
                                )
                              : Container()
                        ],
                      );
                    },
                    selector: (_, homeProvider) => homeProvider.curCartCount,
                  ),
                  title: Text(getTranslated(context, 'CART')!),
                  activeColor: colors.primary,
                ),
                BottomBarItem(
                  icon: _selBottom == 4
                      ? SvgPicture.asset(
                          "${imagePath}profile01.svg",
                          color: colors.primary,
                        )
                      : SvgPicture.asset(
                          "${imagePath}profile.svg",
                          color: colors.primary,
                        ),
                  title: const Text('Profile'),
                  activeColor: colors.primary,
                ),
              ],
            ),
          ),
        ));
  }

  @override
  void dispose() {
    super.dispose();
  }

  openwhatsapp() async {
    var whatsapp = "+971509569607";
    var whatsappURl_android = "whatsapp://send?phone=" +
        whatsapp +
        "&text=Hello, I am Looking for Vape.";
    var whatappURL_ios =
        "https://wa.me/$whatsapp?text=${Uri.parse("Hello, I am Looking for Vape.")}";
    if (Platform.isIOS) {
      // for iOS phone only
      if (await canLaunch(whatappURL_ios)) {
        await launch(whatappURL_ios, forceSafariVC: false);
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: new Text("whatsapp no installed")));
      }
    } else {
      // android , web
      if (await canLaunch(whatsappURl_android)) {
        await launch(whatsappURl_android);
      } else {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: new Text("whatsapp no installed")));
      }
    }
  }

  Future<void> openFaceBook() async {
    /* numeric value ကို https://lookup-id.com/ မှာ ရှာပါ */
    String fbProtocolUrl = "fb://page/578155247450779";
    String fallbackUrl = "https://www.facebook.com/dannyinfluencer";
    try {
      bool launched = await launch(fbProtocolUrl, forceSafariVC: true);
      print("launching..." + fbProtocolUrl);
      if (!launched) {
        print("can't launch");
        await launch(fallbackUrl, forceSafariVC: true);
      }
    } catch (e) {
      print("can't launch exp " + e.toString());
      await launch(fallbackUrl, forceSafariVC: false);
    }
  }

  Future<void> launchWeb() async {
    var url = "https://danientakly.com/";
    if (await canLaunchUrl(Uri.parse(url)))
      await launchUrl(Uri.parse(url));
    else
      // can't launch url, there is some error
      throw "Could not launch $url";
  }
}

void openInstagram() async {
  var url = 'https://www.instagram.com/dani_entakly/';
  if (await canLaunch(url)) {
    await launch(
      url,
      universalLinksOnly: true,
    );
  } else {
    throw 'There was a problem to open the url: $url';
  }
}
