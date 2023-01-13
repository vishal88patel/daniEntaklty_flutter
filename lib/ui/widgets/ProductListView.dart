import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

import '../../Helper/String.dart';
import '../../Model/Section_Model.dart';
import '../../Screen/Product_Detail.dart';
import '../styles/Color.dart';
import '../styles/DesignConfig.dart';

Widget productItemView(int index,List<Product> productList,BuildContext context,String from) {
  if (index < productList.length) {
    String? offPer;
    double price =
    double.parse(productList[index].prVarientList![0].disPrice!);
    if (price == 0) {
      price = double.parse(productList[index].prVarientList![0].price!);
    } else {
      double off =
          double.parse(productList[index].prVarientList![0].price!) - price;
      offPer = ((off * 100) /
          double.parse(productList[index].prVarientList![0].price!))
          .toStringAsFixed(2);
    }

    double width = deviceWidth! * 0.45;

    return SizedBox(
        height: 255,
        width: width,
        child: Card(
          elevation: 0.2,
          margin: const EdgeInsetsDirectional.only(bottom: 5, end: 8),
          child: InkWell(
            borderRadius: BorderRadius.circular(4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    clipBehavior: Clip.none,
                    children: [
                      Padding(
                          padding: const EdgeInsetsDirectional.only(top: 8.0),
                          child: ClipRRect(
                            borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(5),
                                topRight: Radius.circular(5)),
                            child: Hero(
                              tag: "$from$index${productList[index].id}0",
                              child: FadeInImage(
                                image:
                                NetworkImage(productList[index].image!),
                                height: double.maxFinite,
                                width: double.maxFinite,
                                fit: extendImg ? BoxFit.fill : BoxFit.contain,
                                imageErrorBuilder:
                                    (context, error, stackTrace) =>
                                    erroWidget(
                                      double.maxFinite,
                                    ),
                                placeholder: placeHolder(
                                  double.maxFinite,
                                ),
                              ),
                            ),
                          )),
                      const Divider(
                        height: 1,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsetsDirectional.only(
                    start: 5.0,
                    top: 5,
                  ),
                  child: Row(
                    children: [
                      RatingBarIndicator(
                        rating: double.parse(productList[index].rating!),
                        itemBuilder: (context, index) => const Icon(
                          Icons.star_rate_rounded,
                          color: Colors.amber,
                        ),
                        unratedColor: Colors.grey.withOpacity(0.5),
                        itemCount: 5,
                        itemSize: 12.0,
                        direction: Axis.horizontal,
                        itemPadding: const EdgeInsets.all(0),
                      ),
                      Text(
                        " (${productList[index].noOfRating!})",
                        style: Theme.of(context).textTheme.overline,
                      )
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsetsDirectional.only(
                      start: 5.0, top: 5, bottom: 5),
                  child: Text(
                    productList[index].name!,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.fontColor,
                        fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
          Padding(
            padding: const EdgeInsetsDirectional.only(
                start: 5.0),
            child: Row(
                  children: [
                    Text('${getPriceFormat(context, price)!} ',
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.fontColor,
                            fontWeight: FontWeight.bold)),
                    Text(
                      double.parse(productList[index]
                          .prVarientList![0]
                          .disPrice!) !=
                          0
                          ? "${productList[index]
                          .prVarientList![0]
                          .price!} Puff"
                      /* getPriceFormat(
                          context,
                          double.parse(productList[index]
                              .prVarientList![0]
                              .price!))!*/
                          : "",
                      style: Theme.of(context).textTheme.overline!.copyWith(
                          fontSize: 13,
                          letterSpacing: 0),
                    ),
                  ],
                )),
              ],
            ),
            onTap: () {
              Product model = productList[index];
              currentHero=from;
              Navigator.push(
                context,
                PageRouteBuilder(
                    pageBuilder: (_, __, ___) => ProductDetail(
                        model: model,
                        secPos: 0,
                        index: index,
                        list: true)),
              );
            },
          ),
        ));
  } else {
    return Container();
  }
}