const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

exports.createWorker = functions.https.onCall(async (data, context) => {
  // 🔒 تأكد أن المستخدم مسجل
  if (!context.auth) {
    throw new functions.https.HttpsError(
        "unauthenticated",
        "يجب تسجيل الدخول",
    );
  }

  const uid = context.auth.uid;

  // 🔍 تحقق أن المستخدم Administration
  const userDoc = await admin.firestore()
      .collection("users")
      .doc(uid)
      .get();

  if (!userDoc.exists || userDoc.data().role !== "administration") {
    throw new functions.https.HttpsError(
        "permission-denied",
        "فقط الإدارة يمكنها إنشاء عمال",
    );
  }

  const {email, password, workerType} = data;

  // 🔨 إنشاء حساب Auth
  const userRecord = await admin.auth().createUser({
    email,
    password,
  });

  // 💾 حفظ في Firestore
  await admin.firestore()
      .collection("users")
      .doc(userRecord.uid)
      .set({
        email: email,
        role: "worker",
        workerType: workerType,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

  return {success: true};
});
