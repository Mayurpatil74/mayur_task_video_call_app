// import 'package:flutter/material.dart';
// import 'package:flutter_webrtc/flutter_webrtc.dart';
// import '../services/signalling.service.dart';
//
// class CallScreen extends StatefulWidget {
//   final String callerId, calleeId;
//   final dynamic offer;
//   const CallScreen({
//     super.key,
//     this.offer,
//     required this.callerId,
//     required this.calleeId,
//   });
//
//   @override
//   State<CallScreen> createState() => _CallScreenState();
// }
//
// class _CallScreenState extends State<CallScreen> {
//   // socket instance
//   final socket = SignallingService.instance.socket;
//
//   // videoRenderer for localPeer
//   final _localRTCVideoRenderer = RTCVideoRenderer();
//
//   // videoRenderer for remotePeer
//   final _remoteRTCVideoRenderer = RTCVideoRenderer();
//
//   // mediaStream for localPeer
//   MediaStream? _localStream;
//
//   // RTC peer connection
//   RTCPeerConnection? _rtcPeerConnection;
//
//   // list of rtcCandidates to be sent over signalling
//   List<RTCIceCandidate> rtcIceCadidates = [];
//
//   // media status
//   bool isAudioOn = true, isVideoOn = true, isFrontCameraSelected = true;
//
//   @override
//   void initState() {
//     // initializing renderers
//     _localRTCVideoRenderer.initialize();
//     _remoteRTCVideoRenderer.initialize();
//
//     // setup Peer Connection
//     _setupPeerConnection();
//     super.initState();
//   }
//
//   @override
//   void setState(fn) {
//     if (mounted) {
//       super.setState(fn);
//     }
//   }
//
//   _setupPeerConnection() async {
//     // create peer connection
//     _rtcPeerConnection = await createPeerConnection({
//       'iceServers': [
//         {
//           'urls': [
//             'stun:stun1.l.google.com:19302',
//             'stun:stun2.l.google.com:19302'
//           ]
//         }
//       ]
//     });
//
//     // listen for remotePeer mediaTrack event
//     _rtcPeerConnection!.onTrack = (event) {
//       _remoteRTCVideoRenderer.srcObject = event.streams[0];
//       setState(() {});
//     };
//
//     // get localStream
//     _localStream = await navigator.mediaDevices.getUserMedia({
//       'audio': isAudioOn,
//       'video': isVideoOn
//           ? {'facingMode': isFrontCameraSelected ? 'user' : 'environment'}
//           : false,
//     });
//
//     // add mediaTrack to peerConnection
//     _localStream!.getTracks().forEach((track) {
//       _rtcPeerConnection!.addTrack(track, _localStream!);
//     });
//
//     // set source for local video renderer
//     _localRTCVideoRenderer.srcObject = _localStream;
//     setState(() {});
//
//     // for Incoming call
//     if (widget.offer != null) {
//       // listen for Remote IceCandidate
//       socket!.on("IceCandidate", (data) {
//         String candidate = data["iceCandidate"]["candidate"];
//         String sdpMid = data["iceCandidate"]["id"];
//         int sdpMLineIndex = data["iceCandidate"]["label"];
//
//         // add iceCandidate
//         _rtcPeerConnection!.addCandidate(RTCIceCandidate(
//           candidate,
//           sdpMid,
//           sdpMLineIndex,
//         ));
//       });
//
//       // set SDP offer as remoteDescription for peerConnection
//       await _rtcPeerConnection!.setRemoteDescription(
//         RTCSessionDescription(widget.offer["sdp"], widget.offer["type"]),
//       );
//
//       // create SDP answer
//       RTCSessionDescription answer = await _rtcPeerConnection!.createAnswer();
//
//       // set SDP answer as localDescription for peerConnection
//       _rtcPeerConnection!.setLocalDescription(answer);
//
//       // send SDP answer to remote peer over signalling
//       socket!.emit("answerCall", {
//         "callerId": widget.callerId,
//         "sdpAnswer": answer.toMap(),
//       });
//     }
//     // for Outgoing Call
//     else {
//       // listen for local iceCandidate and add it to the list of IceCandidate
//       _rtcPeerConnection!.onIceCandidate =
//           (RTCIceCandidate candidate) => rtcIceCadidates.add(candidate);
//
//       // when call is accepted by remote peer
//       socket!.on("callAnswered", (data) async {
//         // set SDP answer as remoteDescription for peerConnection
//         await _rtcPeerConnection!.setRemoteDescription(
//           RTCSessionDescription(
//             data["sdpAnswer"]["sdp"],
//             data["sdpAnswer"]["type"],
//           ),
//         );
//
//         // send iceCandidate generated to remote peer over signalling
//         for (RTCIceCandidate candidate in rtcIceCadidates) {
//           socket!.emit("IceCandidate", {
//             "calleeId": widget.calleeId,
//             "iceCandidate": {
//               "id": candidate.sdpMid,
//               "label": candidate.sdpMLineIndex,
//               "candidate": candidate.candidate
//             }
//           });
//         }
//       });
//
//       // create SDP Offer
//       RTCSessionDescription offer = await _rtcPeerConnection!.createOffer();
//
//       // set SDP offer as localDescription for peerConnection
//       await _rtcPeerConnection!.setLocalDescription(offer);
//
//       // make a call to remote peer over signalling
//       socket!.emit('makeCall', {
//         "calleeId": widget.calleeId,
//         "sdpOffer": offer.toMap(),
//       });
//     }
//   }
//
//   _leaveCall() {
//     Navigator.pop(context);
//   }
//
//   _toggleMic() {
//     // change status
//     isAudioOn = !isAudioOn;
//     // enable or disable audio track
//     _localStream?.getAudioTracks().forEach((track) {
//       track.enabled = isAudioOn;
//     });
//     setState(() {});
//   }
//
//   _toggleCamera() {
//     // change status
//     isVideoOn = !isVideoOn;
//
//     // enable or disable video track
//     _localStream?.getVideoTracks().forEach((track) {
//       track.enabled = isVideoOn;
//     });
//     setState(() {});
//   }
//
//   _switchCamera() {
//     // change status
//     isFrontCameraSelected = !isFrontCameraSelected;
//
//     // switch camera
//     _localStream?.getVideoTracks().forEach((track) {
//       // ignore: deprecated_member_use
//       track.switchCamera();
//     });
//     setState(() {});
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Theme.of(context).colorScheme.background,
//       appBar: AppBar(
//         title: const Text("P2P Call App"),
//       ),
//       body: SafeArea(
//         child: Column(
//           children: [
//             Expanded(
//               child: Stack(children: [
//                 RTCVideoView(
//                   _remoteRTCVideoRenderer,
//                   objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
//                 ),
//                 Positioned(
//                   right: 20,
//                   bottom: 20,
//                   child: SizedBox(
//                     height: 150,
//                     width: 120,
//                     child: RTCVideoView(
//                       _localRTCVideoRenderer,
//                       mirror: isFrontCameraSelected,
//                       objectFit:
//                           RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
//                     ),
//                   ),
//                 )
//               ]),
//             ),
//             Padding(
//               padding: const EdgeInsets.symmetric(vertical: 12),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceAround,
//                 children: [
//                   IconButton(
//                     icon: Icon(isAudioOn ? Icons.mic : Icons.mic_off),
//                     onPressed: _toggleMic,
//                   ),
//                   IconButton(
//                     icon: const Icon(Icons.call_end),
//                     iconSize: 30,
//                     onPressed: _leaveCall,
//                   ),
//                   IconButton(
//                     icon: const Icon(Icons.cameraswitch),
//                     onPressed: _switchCamera,
//                   ),
//                   IconButton(
//                     icon: Icon(isVideoOn ? Icons.videocam : Icons.videocam_off),
//                     onPressed: _toggleCamera,
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   @override
//   void dispose() {
//     _localRTCVideoRenderer.dispose();
//     _remoteRTCVideoRenderer.dispose();
//     _localStream?.dispose();
//     _rtcPeerConnection?.dispose();
//     super.dispose();
//   }
// }

import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:flutter_webrtc_app/services/signalling.service.dart';
// Your signaling service

class CallScreen extends StatefulWidget {
  final String callerId, calleeId;

  const CallScreen({
    Key? key,
    required this.callerId,
    required this.calleeId,
  }) : super(key: key);

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  final _localRTCVideoRenderer = RTCVideoRenderer();
  final _remoteRTCVideoRenderer = RTCVideoRenderer();
  MediaStream? _localStream;
  RTCPeerConnection? _rtcPeerConnection;
  bool isAudioOn = true, isVideoOn = true, isFrontCameraSelected = true;

  @override
  void initState() {
    super.initState();
    _localRTCVideoRenderer.initialize();
    _remoteRTCVideoRenderer.initialize();
    _setupPeerConnection();
  }

  Future<void> _setupPeerConnection() async {
    // Create peer connection
    _rtcPeerConnection = await createPeerConnection({
      'iceServers': [
        {
          'urls': ['stun:stun.l.google.com:19302']
        }
      ],
    });

    // Set up track handling (remote track)
    _rtcPeerConnection!.onTrack = (event) {
      if (event.streams.isNotEmpty) {
        _remoteRTCVideoRenderer.srcObject = event.streams[0];
        setState(() {});
      }
    };

    // Set up local media stream
    _localStream = await navigator.mediaDevices.getUserMedia({
      'audio': isAudioOn,
      'video': isVideoOn
          ? {'facingMode': isFrontCameraSelected ? 'user' : 'environment'}
          : false,
    });

    // Add media tracks to peer connection
    _localStream!.getTracks().forEach((track) {
      _rtcPeerConnection!.addTrack(track, _localStream!);
    });

    // Set the local video source for the local video renderer
    _localRTCVideoRenderer.srcObject = _localStream;
    setState(() {});

    // Make the call if initiating
    _makeCall();
  }

  // Function to make a call (create offer)
  Future<void> _makeCall() async {
    final offer = await _rtcPeerConnection!.createOffer();
    await _rtcPeerConnection!.setLocalDescription(offer);

    // Send the offer to the signaling server
    SignallingService.instance.socket!.emit('makeCall', {
      'calleeId': widget.calleeId,
      'sdpOffer': offer.toMap(),
    });

    // Listen for the answer
    SignallingService.instance.socket!.on('callAnswered', (data) async {
      final answer = RTCSessionDescription(
          data['sdpAnswer']['sdp'], data['sdpAnswer']['type']);
      await _rtcPeerConnection!.setRemoteDescription(answer);
    });

    // Listen for ICE candidates and send them
    SignallingService.instance.socket!.on('IceCandidate', (data) {
      final candidate = RTCIceCandidate(
        data['iceCandidate']['candidate'],
        data['iceCandidate']['id'],
        data['iceCandidate']['label'],
      );
      _rtcPeerConnection!.addCandidate(candidate);
    });
  }

  // Function to end the call
  void _endCall() {
    _rtcPeerConnection?.close();
    Navigator.pop(context);
  }

  @override
  void dispose() {
    _localRTCVideoRenderer.dispose();
    _remoteRTCVideoRenderer.dispose();
    _localStream?.dispose();
    _rtcPeerConnection?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Video Call'),
        actions: [
          IconButton(
            icon: Icon(Icons.call_end),
            onPressed: _endCall,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                RTCVideoView(_remoteRTCVideoRenderer),
                Positioned(
                  right: 20,
                  bottom: 20,
                  child: SizedBox(
                    width: 120,
                    height: 150,
                    child: RTCVideoView(_localRTCVideoRenderer),
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(isAudioOn ? Icons.mic : Icons.mic_off),
                onPressed: () {
                  isAudioOn = !isAudioOn;
                  _localStream?.getAudioTracks().forEach((track) {
                    track.enabled = isAudioOn;
                  });
                  setState(() {});
                },
              ),
              IconButton(
                icon: Icon(isVideoOn ? Icons.videocam : Icons.videocam_off),
                onPressed: () {
                  isVideoOn = !isVideoOn;
                  _localStream?.getVideoTracks().forEach((track) {
                    track.enabled = isVideoOn;
                  });
                  setState(() {});
                },
              ),
              IconButton(
                icon: Icon(Icons.cameraswitch),
                onPressed: () {
                  isFrontCameraSelected = !isFrontCameraSelected;
                  _localStream?.getVideoTracks().forEach((track) {
                    // Switch between front and back cameras
                    track.switchCamera();
                  });
                  setState(() {});
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
