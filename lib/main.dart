import 'package:flutter/material.dart';

import 'package:oauth2/oauth2.dart' as oauth2;

import 'package:url_launcher/url_launcher.dart';
import 'package:uni_links/uni_links.dart';

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

final authorizationEndpoint = Uri.parse('https://login.microsoftonline.com/294c7ede-2387-42ab-bbff-e5eb67ca3aee/oauth2/v2.0/authorize');
//final authorizationEndpoint = Uri.parse('294c7ede-2387-42ab-bbff-e5eb67ca3aee');
final tokenEndpoint = Uri.parse('https://login.microsoftonline.com/294c7ede-2387-42ab-bbff-e5eb67ca3aee/oauth2/v2.0/token');

final identifier = 'bbe45ebc-fb38-48d8-8abd-9c5a9d38a6fd';
final secret = 'xR-7Q~wBycyWLmcH58q7qfY-5CJ4RSPSxpysg';

final redirectUrl = Uri.parse('https://login.microsoftonline.com/common/oauth2/nativeclient');
final credentialsFile = File('~/.myapp/credentials.json'); //TODO:Check for correct location ?

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget{
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context)
  {
    return MaterialApp(
      title: 'AAD Oauth Flutter',
      theme: ThemeData(
          primarySwatch: Colors.blue
      ),
      home: const MyHomePage(title: 'AAD OAuth Home 2'),
    );
  }
}

Future<oauth2.Client> createClient() async {
  var exists = await credentialsFile.exists();

  print('exists = $exists');

  if(exists) {
    var credentials =
        oauth2.Credentials.fromJson(await credentialsFile.readAsString());
    return oauth2.Client(credentials, identifier: identifier, secret: secret);
  }

  var grant = oauth2.AuthorizationCodeGrant(
    identifier, authorizationEndpoint, tokenEndpoint, secret: secret);

  print('grant = $grant');
  print('redirectUrl = $redirectUrl');

  var authorizationUrl = grant.getAuthorizationUrl(redirectUrl);

  print ('authorizationUrl = $authorizationUrl');

  if(await canLaunch(authorizationUrl.toString())) {
    await launch(authorizationUrl.toString());
  }

  //await redirect(authorizationUrl);

  Uri? responseUrl;





  responseUrl = await listen(redirectUrl);

  return await grant.handleAuthorizationResponse(responseUrl.queryParameters);
}

Future<void> redirect(Uri url) async {
  /*
  if(await canLaunch(url.toString())) {
    await launch(url.toString());
  }

   */
}

Future<Uri> listen (Uri url) async {



  return Uri();
}

class MyHomePage extends StatefulWidget{
  const MyHomePage({Key? key, required this.title}) : super(key: key);
  final String title;
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage>{
  /*
  static final Config config = Config(
      tenant: '294c7ede-2387-42ab-bbff-e5eb67ca3aee',
      clientId: 'bbe45ebc-fb38-48d8-8abd-9c5a9d38a6fd',
      scope: 'openid profile offline_access',
      redirectUri: 'https://login.live.com/oauth20_desktop.srf'
  );
  final AadOAuth oauth = AadOAuth(config);
  */
  String? accessToken;



  @override
  Widget build(BuildContext context){
    //oauth.setWebViewScreenSizeFromMedia(MediaQuery.of(context));

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: ListView(
        children: <Widget>[
          ListTile(
            title: Text(
              'AzureAD OAuth',
              style: Theme.of(context).textTheme.headline5,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.launch),
            title: const Text('Login'),
            onTap: () {
              login();
            },
          ),
          ListTile(
              leading: const Icon(Icons.list_alt),
              title: const Text('Show me'),
              onTap: () {
                listData();
              }
          ),
          ListTile(
            leading: const Icon(Icons.delete),
            title: const Text('Logout'),
            onTap: () {
              logout();
            },
          )
        ],
      ),
    );
  }

  void showError(dynamic ex){
    showMessage(ex.toString());
  }

  void showMessage(String text){
    var alert = AlertDialog(
      content: Text(text),
      actions: <Widget>[
        TextButton(
            onPressed: (){
              Navigator.pop(context);
            },
            child: const Text('Ok')
        )
      ],
    );
    showDialog(
        context: context,
        builder: (BuildContext context) => alert
    );
  }


  void listData() async {
    try{

      final mSlamData = await fetchMSlamData();

      showMessage('User = ${mSlamData.employeeResponse.employeeName}');

    }catch(e){
      showError(e);
    }
  }

  void login() async {


    try {
      var client = await createClient();

      accessToken = client.credentials.accessToken;

    }catch(e){
      showError(e);
    }


    /*
    try{
      await oauth.login();
      accessToken = await oauth.getAccessToken();
      showMessage('Logged in successfully, your access token: $accessToken');
    }catch(e){
      showError(e);
    }*/

  }

  void logout() async
  {
    /*
    await oauth.logout();
    showMessage('Logged out');

     */
  }


  Future<MSlamData> fetchMSlamData() async {

    //accessToken = ''; //await oauth.getAccessToken();

    showMessage(accessToken as String);

    final response = await http.get(
      Uri.parse('https://api.norva24.no:5010/Slam/meg'),
      headers: {
        HttpHeaders.authorizationHeader : 'Bearer ${accessToken as String}'
      },
    );

    showMessage(response.body.toString());

    final responseJson = jsonDecode(response.body);

    return MSlamData.fromJson(responseJson);
  }


}

class MSlamData {

  MSlamData({
    required this.success,
    required this.message,
    required this.employeeResponse,
  });

  final bool? success;
  final String? message;
  final MSlamEmployeeResponse employeeResponse;

  factory MSlamData.fromJson(Map<String, dynamic> data) {
    final success = data['success'] as bool?;
    final message = data['message'] as String?;
    //final employeeData = data['employee'] as dynamic;

    final employee = MSlamEmployeeResponse.fromJson(data['data'] as dynamic);

    return MSlamData(
        success: success,
        message: message,
        employeeResponse: employee);

  }

}


class MSlamEmployeeResponse{

  MSlamEmployeeResponse({
    required this.employeeId,
    required this.companyId,
    required this.emailAddress,
    required this.employeeName
  });

  final int? employeeId;
  final int? companyId;
  final String? emailAddress;
  final String? employeeName;



  factory MSlamEmployeeResponse.fromJson(Map<String, dynamic> data){
    final employeeId = data['id'] as int?;
    final companyId = data['firmaId'] as int?;
    final emailAddress = data['epostaddresse'] as String?;
    final employeeName = data['namn'] as String?;

    return MSlamEmployeeResponse(
        employeeId: employeeId,
        companyId: companyId,
        emailAddress: emailAddress,
        employeeName: employeeName
    );
  }

}

