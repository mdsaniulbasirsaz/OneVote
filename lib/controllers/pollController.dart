import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:OneVote/models/pollModel.dart';
class PollController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Create a new Poll
  Future<void> createPoll(Poll poll) async {
    try {
      await _db.collection('polls').doc(poll.pollId).set(poll.toMap());
      print('Poll created successfully');
    } catch (e) {
      print('Error creating poll: $e');
    }
  }

  // Get Poll by Poll ID
  Future<Poll?> getPoll(String pollId) async {
    try {
      DocumentSnapshot doc = await _db.collection('polls').doc(pollId).get();
      if (doc.exists) {
        return Poll.fromMap(doc.data() as Map<String, dynamic>);
      } else {
        print('Poll not found');
        return null;
      }
    } catch (e) {
      print('Error getting poll: $e');
      return null;
    }
  }

  // Update Poll (e.g., change title or voting description)
  Future<void> updatePoll(Poll poll) async {
    try {
      await _db.collection('polls').doc(poll.pollId).update(poll.toMap());
      print('Poll updated successfully');
    } catch (e) {
      print('Error updating poll: $e');
    }
  }

  // Delete Poll
  Future<void> deletePoll(String pollId) async {
    try {
      await _db.collection('polls').doc(pollId).delete();
      print('Poll deleted successfully');
    } catch (e) {
      print('Error deleting poll: $e');
    }
  }

  // Get all Polls (optional)
  Future<List<Poll>> getAllPolls() async {
    try {
      QuerySnapshot snapshot = await _db.collection('polls').get();
      List<Poll> polls = snapshot.docs
          .map((doc) => Poll.fromMap(doc.data() as Map<String, dynamic>))
          .toList();
      return polls;
    } catch (e) {
      print('Error getting polls: $e');
      return [];
    }
  }

  // Add a voter to a Poll
  Future<void> addVoterToPoll(String pollId, Voter voter) async {
    try {
      DocumentReference pollRef = _db.collection('polls').doc(pollId);
      await pollRef.update({
        'voterList': FieldValue.arrayUnion([voter.toMap()])
      });
      print('Voter added to poll');
    } catch (e) {
      print('Error adding voter: $e');
    }
  }

  // Increment Vote for a Candidate in a Poll
  Future<void> incrementVote(String pollId, String positionTitle, String candidateId) async {
    try {
      DocumentReference pollRef = _db.collection('polls').doc(pollId);
      DocumentSnapshot pollDoc = await pollRef.get();
      if (pollDoc.exists) {
        Poll poll = Poll.fromMap(pollDoc.data() as Map<String, dynamic>);
        Position? position = poll.positions.firstWhere(
          (pos) => pos.positionTitle == positionTitle,
          orElse: () => Position(positionTitle: positionTitle, candidates: []),
        );
        Candidate? candidate = position.candidates.firstWhere(
          (cand) => cand.candidateId == candidateId,
          orElse: () => Candidate(candidateId: candidateId, name: '', image: ''),
        );
        
        // Increment vote count
        candidate.incrementVote();

        // Update the poll document
        await pollRef.update({
          'positions': poll.positions.map((pos) {
            if (pos.positionTitle == positionTitle) {
              return Position(positionTitle: pos.positionTitle, candidates: pos.candidates).toMap();
            }
            return pos.toMap();
          }).toList(),
        });

        print('Vote incremented for candidate');
      }
    } catch (e) {
      print('Error incrementing vote: $e');
    }
  }

  // Get a list of voters for a specific poll
  Future<List<Voter>> getVoters(String pollId) async {
    try {
      DocumentSnapshot pollDoc = await _db.collection('polls').doc(pollId).get();
      if (pollDoc.exists) {
        Poll poll = Poll.fromMap(pollDoc.data() as Map<String, dynamic>);
        return poll.voterList;
      } else {
        print('Poll not found');
        return [];
      }
    } catch (e) {
      print('Error getting voters: $e');
      return [];
    }
  }

  //Fetch all polls where isPayment ==1
  Future<List<Poll>> fetchPolls() async {
    try{
        QuerySnapshot snapshot = await _db
          .collection('polls')
          .where('isPayment', isEqualTo: 1)
          .get();
        return snapshot.docs
        .map((doc) => Poll.fromMap(doc.data() as Map<String, dynamic>))
        .toList();
    } catch(e){
      print('Error fetching polls: $e');
      return [];
    }
  }
}
