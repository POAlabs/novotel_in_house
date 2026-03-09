/**
 * Firebase Cloud Functions for Novotel In-House Push Notifications
 * 
 * These functions trigger on Firestore document changes and send
 * push notifications to relevant users via Firebase Cloud Messaging.
 * 
 * Notification Types:
 * 1. New issue created → Notify department staff
 * 2. Issue resolved → Notify original reporter
 * 3. Issue reassigned → Notify new department staff
 * 4. Urgent issue → Notify all admins
 */

const { onDocumentCreated, onDocumentUpdated } = require("firebase-functions/v2/firestore");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore } = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");

// Initialize Firebase Admin
initializeApp();

const db = getFirestore();
const messaging = getMessaging();

/**
 * Helper: Format department name to topic format
 * e.g., "Front Office" → "department_front_office"
 */
function getDepartmentTopic(department) {
  return `department_${department.toLowerCase().replace(/ /g, '_')}`;
}

/**
 * Helper: Get priority emoji
 */
function getPriorityEmoji(priority) {
  switch (priority) {
    case 'Urgent': return '🚨';
    case 'High': return '⚠️';
    case 'Medium': return '📋';
    case 'Low': return '📝';
    default: return '📋';
  }
}

/**
 * Helper: Send notification to a topic
 */
async function sendToTopic(topic, title, body, data = {}) {
  const message = {
    topic: topic,
    notification: {
      title: title,
      body: body,
    },
    data: {
      ...data,
      click_action: 'FLUTTER_NOTIFICATION_CLICK',
    },
    android: {
      priority: 'high',
      notification: {
        channelId: 'novotel_issues',
        priority: 'high',
        defaultSound: true,
        defaultVibrateTimings: true,
      },
    },
    apns: {
      payload: {
        aps: {
          alert: {
            title: title,
            body: body,
          },
          sound: 'default',
          badge: 1,
        },
      },
    },
  };

  try {
    const response = await messaging.send(message);
    console.log(`✅ Notification sent to topic ${topic}:`, response);
    return response;
  } catch (error) {
    console.error(`❌ Error sending to topic ${topic}:`, error);
    throw error;
  }
}

/**
 * Helper: Send notification to specific user by FCM token
 */
async function sendToUser(fcmToken, title, body, data = {}) {
  if (!fcmToken) {
    console.log('⚠️ No FCM token provided, skipping user notification');
    return null;
  }

  const message = {
    token: fcmToken,
    notification: {
      title: title,
      body: body,
    },
    data: {
      ...data,
      click_action: 'FLUTTER_NOTIFICATION_CLICK',
    },
    android: {
      priority: 'high',
      notification: {
        channelId: 'novotel_issues',
        priority: 'high',
        defaultSound: true,
        defaultVibrateTimings: true,
      },
    },
    apns: {
      payload: {
        aps: {
          alert: {
            title: title,
            body: body,
          },
          sound: 'default',
          badge: 1,
        },
      },
    },
  };

  try {
    const response = await messaging.send(message);
    console.log(`✅ Notification sent to user:`, response);
    return response;
  } catch (error) {
    // Handle invalid token - token may be expired or unregistered
    if (error.code === 'messaging/registration-token-not-registered' ||
        error.code === 'messaging/invalid-registration-token') {
      console.log('⚠️ Invalid FCM token, user may have uninstalled app');
      return null;
    }
    console.error(`❌ Error sending to user:`, error);
    throw error;
  }
}

/**
 * TRIGGER: New issue created
 * Notifies department staff and managers when a new issue is reported
 */
exports.onIssueCreated = onDocumentCreated("issues/{issueId}", async (event) => {
  const snapshot = event.data;
  if (!snapshot) {
    console.log("No data associated with the event");
    return null;
  }

  const issue = snapshot.data();
  const issueId = event.params.issueId;

  console.log(`📝 New issue created: ${issueId}`);
  console.log(`   Department: ${issue.department}`);
  console.log(`   Priority: ${issue.priority}`);
  console.log(`   Floor: ${issue.floor}`);

  const emoji = getPriorityEmoji(issue.priority);
  const topic = getDepartmentTopic(issue.department);
  
  // Truncate description for notification
  const shortDesc = issue.description.length > 50 
    ? issue.description.substring(0, 47) + '...' 
    : issue.description;

  // Send to department topic
  await sendToTopic(
    topic,
    `${emoji} New Issue - Floor ${issue.floor}`,
    shortDesc,
    {
      type: 'new_issue',
      issueId: issueId,
      floor: issue.floor,
      department: issue.department,
      priority: issue.priority,
    }
  );

  // If urgent, also notify all system admins
  if (issue.priority === 'Urgent') {
    await sendToTopic(
      'role_system_admin',
      `🚨 URGENT Issue - ${issue.department}`,
      `Floor ${issue.floor}: ${shortDesc}`,
      {
        type: 'urgent_issue',
        issueId: issueId,
        floor: issue.floor,
        department: issue.department,
        priority: 'Urgent',
      }
    );
  }

  return null;
});

/**
 * TRIGGER: Issue updated (resolved or reassigned)
 * - Notifies reporter when their issue is resolved
 * - Notifies new department when issue is reassigned
 */
exports.onIssueUpdated = onDocumentUpdated("issues/{issueId}", async (event) => {
  const beforeData = event.data.before.data();
  const afterData = event.data.after.data();
  const issueId = event.params.issueId;

  console.log(`📝 Issue updated: ${issueId}`);

  // Check if issue was just resolved
  if (beforeData.status === 'Ongoing' && afterData.status === 'Completed') {
    console.log(`   Status changed to Completed`);
    
    // Get reporter's FCM token from users collection
    const reporterId = afterData.reportedBy;
    if (reporterId) {
      try {
        const userDoc = await db.collection('users').doc(reporterId).get();
        if (userDoc.exists) {
          const userData = userDoc.data();
          const fcmToken = userData.fcmToken;
          
          await sendToUser(
            fcmToken,
            '✅ Issue Resolved',
            `Your issue "${afterData.description.substring(0, 40)}..." has been resolved`,
            {
              type: 'issue_resolved',
              issueId: issueId,
              floor: afterData.floor,
              department: afterData.department,
            }
          );
        }
      } catch (error) {
        console.error('Error notifying reporter:', error);
      }
    }
  }

  // Check if department was changed (reassigned)
  if (beforeData.department !== afterData.department) {
    console.log(`   Reassigned from ${beforeData.department} to ${afterData.department}`);
    
    const newTopic = getDepartmentTopic(afterData.department);
    const emoji = getPriorityEmoji(afterData.priority);
    
    const shortDesc = afterData.description.length > 50 
      ? afterData.description.substring(0, 47) + '...' 
      : afterData.description;

    await sendToTopic(
      newTopic,
      `${emoji} Issue Assigned - Floor ${afterData.floor}`,
      `Transferred from ${beforeData.department}: ${shortDesc}`,
      {
        type: 'issue_reassigned',
        issueId: issueId,
        floor: afterData.floor,
        department: afterData.department,
        priority: afterData.priority,
        previousDepartment: beforeData.department,
      }
    );
  }

  // Check if priority was escalated to Urgent
  if (beforeData.priority !== 'Urgent' && afterData.priority === 'Urgent') {
    console.log(`   Priority escalated to Urgent`);
    
    const shortDesc = afterData.description.length > 50 
      ? afterData.description.substring(0, 47) + '...' 
      : afterData.description;

    await sendToTopic(
      'role_system_admin',
      `🚨 Priority Escalated to URGENT`,
      `${afterData.department} - Floor ${afterData.floor}: ${shortDesc}`,
      {
        type: 'urgent_escalation',
        issueId: issueId,
        floor: afterData.floor,
        department: afterData.department,
        priority: 'Urgent',
      }
    );
  }

  return null;
});
