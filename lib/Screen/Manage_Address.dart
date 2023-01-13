import 'dart:async';

import 'package:eshop/Provider/UserProvider.dart';
import 'package:eshop/Screen/Cart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../ui/styles/DesignConfig.dart';
import '../ui/widgets/AppBtn.dart';
import '../ui/styles/Color.dart';
import '../ui/widgets/user_custom_radio.dart';
import '../Helper/Session.dart';
import '../Helper/String.dart';
import '../Model/User.dart';
import '../ui/widgets/SimpleAppBar.dart';
import 'Add_Address.dart';
import 'HomePage.dart';
import 'Login.dart';

class ManageAddress extends StatefulWidget {
  final bool? home;

  const ManageAddress({Key? key, this.home}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return StateAddress();
  }
}

class StateAddress extends State<ManageAddress> with TickerProviderStateMixin {
  bool _isLoading = false, _isProgress = false;
  Animation? buttonSqueezeanimation;
  AnimationController? buttonController;
  bool _isNetworkAvail = true;
  List<RadioModel> addModel = [];
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey =
      GlobalKey<RefreshIndicatorState>();

  @override
  void initState() {
    super.initState();
    if (CUR_USERID != null && CUR_USERID!.isNotEmpty && CUR_USERID!=""){
      if (widget.home!) {
        if (mounted) {
          setState(() {
            _isLoading = true;
          });
        }
        _getAddress();
      } else {
        addAddressModel();
      }
      buttonController = AnimationController(
          duration: const Duration(milliseconds: 2000), vsync: this);

      buttonSqueezeanimation = Tween(
        begin: deviceWidth! * 0.7,
        end: 50.0,
      ).animate(CurvedAnimation(
        parent: buttonController!,
        curve: const Interval(
          0.0,
          0.150,
        ),
      ));
    }else{
        Navigator.push(
          context,
          CupertinoPageRoute(builder: (context) => const Login()),
        );
    }




  }

  @override
  void dispose() {
    buttonController!.dispose();
    super.dispose();
  }

  Future<void> _playAnimation() async {
    try {
      await buttonController!.forward();
    } on TickerCanceled {}
  }

  Widget noInternet(BuildContext context) {
    return SingleChildScrollView(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        noIntImage(),
        noIntText(context),
        noIntDec(context),
        AppBtn(
          title: getTranslated(context, 'TRY_AGAIN_INT_LBL'),
          btnAnim: buttonSqueezeanimation,
          btnCntrl: buttonController,
          onBtnSelected: () async {
            _playAnimation();

            Future.delayed(const Duration(seconds: 2)).then((_) async {
              _isNetworkAvail = await isNetworkAvailable();
              if (_isNetworkAvail) {
                addressList.clear();
                addModel.clear();
                if (!ISFLAT_DEL) delCharge = 0;
                _getAddress();
              } else {
                await buttonController!.reverse();
                if (mounted) setState(() {});
              }
            });
          },
        )
      ]),
    );
  }

  Future<void> _getAddress() async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        var parameter = {
          USER_ID: CUR_USERID,
        };
        apiBaseHelper.postAPICall(getAddressApi, parameter).then((getdata) {
          bool error = getdata["error"];

          if (!error) {
            var data = getdata["data"];

            addressList =
                (data as List).map((data) => User.fromAddress(data)).toList();

            for (int i = 0; i < addressList.length; i++) {
              if (addressList[i].isDefault == "1") {
                selectedAddress = i;
                selAddress = addressList[i].id;
               /* if (!ISFLAT_DEL) {
                  if (totalPrice < double.parse(addressList[i].freeAmt!)) {
                    delCharge = double.parse(addressList[i].deliveryCharge!);
                  } else {
                    delCharge = 0;
                  }
                }*/
              }
            }

            addAddressModel();
          } else {}
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        }, onError: (error) {
          setSnackbar(error.toString(), context);
        });
      } on TimeoutException catch (_) {}
    } else {
      if (mounted) {
        setState(() {
          _isNetworkAvail = false;
        });
      }
    }
    return;
  }

  Future<void> _refresh() {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }
    addressList.clear();
    addModel.clear();
    if (!ISFLAT_DEL) delCharge = 0;
    return _getAddress();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar:
          getSimpleAppBar(getTranslated(context, "SHIPP_ADDRESS")!, context),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 50.0),
        child: FloatingActionButton(
          onPressed: () async {
            await Navigator.push(
              context,
              CupertinoPageRoute(
                  builder: (context) => AddAddress(
                        update: false,
                        index: addressList.length,
                      )),
            );
            if (mounted) {
              setState(() {
                addModel.clear();
                addAddressModel();
              });
            }
          },
          child: const Icon(Icons.add),
        ),
      ),
      backgroundColor: Theme.of(context).colorScheme.lightWhite,
      body: _isNetworkAvail
          ? Column(
              children: [
                Expanded(
                  child: _isLoading
                      ? shimmer(context)
                      : addressList.isEmpty
                          ? Center(
                              child: Text(getTranslated(context, 'NOADDRESS')!))
                          : Stack(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(10.0),
                                  child: RefreshIndicator(
                                      color: colors.primary,
                                      key: _refreshIndicatorKey,
                                      onRefresh: _refresh,
                                      child: ListView.builder(
                                          physics:
                                              const AlwaysScrollableScrollPhysics(),
                                          itemCount: addressList.length,
                                          itemBuilder: (context, index) {
                                            return addressItem(index);
                                          })),
                                ),
                                showCircularProgress(
                                    _isProgress, colors.primary),
                              ],
                            ),
                ),
              ],
            )
          : noInternet(context),
    );
  }

  Future<void> setAsDefault(int index) async {
    try {
      var data = {
        USER_ID: CUR_USERID,
        ID: addressList[index].id,
        ISDEFAULT: "1",
      };
      apiBaseHelper.postAPICall(updateAddressApi, data).then((getdata) {
        bool error = getdata["error"];
        String? msg = getdata["message"];

        if (!error) {
          // var data = getdata["data"];

          for (User i in addressList) {
            i.isDefault = "0";
          }

          addressList[index].isDefault = "1";
        } else {
          setSnackbar(msg!, context);
        }
        if (mounted) {
          setState(() {
            _isProgress = false;
          });
        }
      }, onError: (error) {
        setSnackbar(error.toString(), context);
      });
    } on TimeoutException catch (_) {
      setSnackbar(getTranslated(context, 'somethingMSg')!, context);
    }
  }

  addressItem(int index) {
    return Consumer<UserProvider>(
        builder: (context, userProvider, _) {
          return Card(
          elevation: 0.2,
          child: InkWell(
            borderRadius: BorderRadius.circular(4),
            onTap: () {
              if (mounted) {
                setState(() {
                  if (!ISFLAT_DEL) {
                    if (oriPrice <
                        double.parse("0")) {
                      delCharge = double.parse(
                          addressList[selectedAddress!].deliveryCharge!);
                     /* if(usedBal>0){
                        totalPrice=delCharge;
                       *//* usedBal=(totalPrice +
                            delCharge);


                        remWalBal = (double.parse(
                            userProvider.curBalance) -
                            (totalPrice +
                                delCharge)
                        );*//*
                      }
                      else
                      {

                      }*/

                    } else {
                      delCharge = 0;
                    }
                    /* if (isStorePickUp == "false") {
                    totalPrice = totalPrice - delCharge;
                  }*/
                  }

                  selectedAddress = index;
                  selAddress = addressList[index].id;

                  if (!ISFLAT_DEL) {
                    if (totalPrice <
                        double.parse("0")) {
                      delCharge = double.parse(
                          addressList[selectedAddress!].deliveryCharge!);

                      print("usedBal*****$usedBal*****${usedBal>0}");
                      /*if(usedBal>0){
                        print("total****${totalPrice +
                            delCharge}");
                        totalPrice=delCharge;
                        *//*usedBal=(totalPrice +
                            delCharge);

                        remWalBal = (double.parse(
                            userProvider.curBalance) -
                            (totalPrice +
                                delCharge)
                        );*//*
                      }
                      else
                      {

                      }*/
                    } else {
                      delCharge = 0;
                    }
                    /*if (isStorePickUp == "false") {
                    totalPrice = totalPrice + delCharge;
                  }
                  else
                    {
                      totalPrice = totalPrice - delCharge;
                    }*/
                  }

                  for (var element in addModel) {
                    element.isSelected = false;
                  }
                  addModel[index].isSelected = true;
                });
              }
            },
            child: RadioItem(addModel[index]),
          ));
        });
    }


  Future<void> deleteAddress(int index) async {
    _isNetworkAvail = await isNetworkAvailable();
    if (_isNetworkAvail) {
      try {
        var parameter = {
          ID: addressList[index].id,
        };
        apiBaseHelper.postAPICall(deleteAddressApi, parameter).then((getdata) {
          bool error = getdata["error"];
          String? msg = getdata["message"];
          if (!error) {
            if (!ISFLAT_DEL) {
              if (addressList.length != 1) {
               /* if (oriPrice <
                    double.parse("0")) {
                  delCharge = double.parse(
                      addressList[selectedAddress!].deliveryCharge!);
                } else {
                  delCharge = 0;
                }*/
               /* if (isStorePickUp == "false") {
                  totalPrice = totalPrice - delCharge;
                }*/

                addressList
                    .removeWhere((item) => item.id == addressList[index].id);
                selectedAddress = 0;
                selAddress = addressList[0].id;

               /* if (totalPrice <
                    double.parse("0")) {
                  delCharge = double.parse(
                      addressList[selectedAddress!].deliveryCharge!);
                } else {
                  delCharge = 0;
                }*/
               /* if (isStorePickUp == "false") {
                  totalPrice = totalPrice + delCharge;
                }*/
              } else {
                addressList
                    .removeWhere((item) => item.id == addressList[index].id);
                selAddress = null;
              }
            } else {
              addressList
                  .removeWhere((item) => item.id == addressList[index].id);
              selAddress = null;
            }

            // addressList.removeWhere((item) => item.id == addressList[index].id);

            addModel.clear();
            addAddressModel();
          } else {
            setSnackbar(msg!, context);
          }
          if (mounted) {
            setState(() {
              _isProgress = false;
            });
          }
        }, onError: (error) {
          setSnackbar(error.toString(), context);
        });
      } on TimeoutException catch (_) {
        setSnackbar(getTranslated(context, 'somethingMSg')!, context);
      }
    } else {
      if (mounted) {
        setState(() {
          _isNetworkAvail = false;
        });
      }
    }
  }

  void addAddressModel() {
    for (int i = 0; i < addressList.length; i++) {
      addModel.add(RadioModel(
          isSelected: i == selectedAddress ? true : false,
          name: "${addressList[i].name!}, ${addressList[i].mobile!}",
          add:
              "${addressList[i].address!}, ${""}, ${addressList[i].city!}, ${addressList[i].state!}, ${addressList[i].country!}, ${addressList[i].pincode!}",
          addItem: addressList[i],
          show: !widget.home!,
          onSetDefault: () {
            if (mounted) {
              setState(() {
                _isProgress = true;
              });
            }
            setAsDefault(i);
          },
          onDeleteSelected: () {
            if (mounted) {
              setState(() {
                _isProgress = true;
              });
            }
            deleteAddress(i);
          },
          onEditSelected: () async {
            await Navigator.push(
                context,
                CupertinoPageRoute(
                  builder: (context) => AddAddress(
                    update: true,
                    index: i,
                  ),
                ));

            if (mounted) {
              setState(() {
                addModel.clear();
                addAddressModel();
              });
            }
          }));
    }
  }
}
