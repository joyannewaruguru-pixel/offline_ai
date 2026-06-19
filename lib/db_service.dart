import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/course_model.dart';
import '../models/lesson_model.dart';
import 'course_model.dart';
import 'lesson_model.dart';

/// Central SQLite database service — singleton.
/// Handles: users, user_activity, courses, lessons, quiz_attempts,
///          user_progress tables.
class DBService {
  DBService._();
  static final DBService instance = DBService._();
  Database? _db;

  get _balance => null;

  get counties => null;

  get is_citizen => null;

  get county => null;

  get tax_rate => null;

  get amount => null;

  get gross => null;

  get salary => null;

  get tax => null;

  get sql => null;

  get conn => null;

  get row => null;

  get result => null;

  get phone => null;

  get credentials => null;

  get secret => null;

  get ch => null;

  get key => null;

  get token => null;

  get shortcode => null;

  get password => null;

  get passkey => null;

  get timestamp => null;

  get payload => null;

  get data => null;

  get res => null;

  // ── Init ──────────────────────────────────────────────────────────────────
  Future<void> init() async {
    final dbPath = await getDatabasesPath();
    _db = await openDatabase(
      join(dbPath, 'learnai_v2.db'),
      version: 1,
      onCreate: _onCreate,
    );
    await _seedIfEmpty();
  }

  Future<void> _onCreate(Database db, int version) async {
    // Users — stores login credentials
    await db.execute('''
      CREATE TABLE users (
        id         INTEGER PRIMARY KEY AUTOINCREMENT,
        name       TEXT NOT NULL,
        email      TEXT UNIQUE NOT NULL,
        password   TEXT NOT NULL,
        level      INTEGER DEFAULT 0,
        created_at TEXT NOT NULL
      )
    ''');

    // User activity log — every action tracked
    await db.execute('''
      CREATE TABLE user_activity (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        user_email  TEXT NOT NULL,
        action      TEXT NOT NULL,
        detail      TEXT,
        occurred_at TEXT NOT NULL
      )
    ''');

    // Courses
    await db.execute('''
      CREATE TABLE courses (
        id        TEXT PRIMARY KEY,
        title     TEXT NOT NULL,
        subtitle  TEXT NOT NULL,
        progress  REAL DEFAULT 0,
        icon_code INTEGER NOT NULL
      )
    ''');

    // Lessons
    await db.execute('''
      CREATE TABLE lessons (
        id           TEXT PRIMARY KEY,
        course_id    TEXT NOT NULL,
        title        TEXT NOT NULL,
        content      TEXT NOT NULL,
        ai_summary   TEXT NOT NULL,
        read_minutes INTEGER NOT NULL,
        progress     REAL DEFAULT 0
      )
    ''');

    // Quiz attempts
    await db.execute('''
      CREATE TABLE quiz_attempts (
        id           INTEGER PRIMARY KEY AUTOINCREMENT,
        lesson_id    TEXT NOT NULL,
        user_email   TEXT NOT NULL,
        score        INTEGER NOT NULL,
        attempted_at TEXT NOT NULL
      )
    ''');

    // Misc user progress (streak, xp, etc.)
    await db.execute('''
      CREATE TABLE user_progress (
        key   TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
  }

  // ── SEED ──────────────────────────────────────────────────────────────────
  Future<void> _seedIfEmpty() async {
    final n = Sqflite.firstIntValue(
        await _db!.rawQuery('SELECT COUNT(*) FROM courses')) ?? 0;
    if (n > 0) return;

    // ── Courses ─────────────────────────────────────────────────────────────
    final courses = [
      {'id':'week1','title':'Intro to Mobile Dev',
        'subtitle':'Week 1 · Flutter setup','progress':1.0,
        'icon_code':Icons.phone_android.codePoint},
      {'id':'week2','title':'Languages & Frameworks',
        'subtitle':'Week 2 · Dart & Flutter basics','progress':1.0,
        'icon_code':Icons.code.codePoint},
      {'id':'week3','title':'UI Development',
        'subtitle':'Week 3 · Widgets & Screens','progress':0.6,
        'icon_code':Icons.dashboard_outlined.codePoint},
      {'id':'week4','title':'Data Management',
        'subtitle':'Week 4 · SQLite & SharedPrefs','progress':0.0,
        'icon_code':Icons.storage_outlined.codePoint},
      {'id':'week5','title':'Networking & APIs',
        'subtitle':'Week 5 · REST & JSON','progress':0.0,
        'icon_code':Icons.cloud_outlined.codePoint},
      {'id':'php','title':'PHP Programming',
        'subtitle':'Web dev · Kenya case study','progress':0.0,
        'icon_code':Icons.web_outlined.codePoint},
      {'id':'python','title':'Python Programming',
        'subtitle':'Data & scripting · Kenyan context','progress':0.0,
        'icon_code':Icons.terminal_outlined.codePoint},
      {'id':'networks','title':'Computer Networks',
        'subtitle':'Networking · Kenya infrastructure','progress':0.0,
        'icon_code':Icons.router_outlined.codePoint},
    ];
    for (final c in courses) await _db!.insert('courses', c);

    // ── Lessons ──────────────────────────────────────────────────────────────
    final lessons = [
      // WEEK 3 ───────────────────────────────────────────────────────────────
      {
        'id':'week3_l1','course_id':'week3',
        'title':'Stateless vs Stateful Widgets',
        'read_minutes':3,'progress':0.6,
        'ai_summary':
        'StatelessWidget = printed photo (never changes). '
            'StatefulWidget = live M-Pesa balance (updates on setState).',
        'content':'''
## Stateless vs Stateful Widgets

Every UI element in Flutter is a **widget**. Think of your Safaricom app —
some parts never change (the logo, menu labels) and some update live
(your airtime balance, data remaining).

### StatelessWidget
Builds once. Use for fixed content.

```dart
class CourseCard extends StatelessWidget {
  final String title;
  const CourseCard({required this.title});
  @override
  Widget build(BuildContext context) => Card(child: Text(title));
}
```

### StatefulWidget
Rebuilds when `setState()` is called — like refreshing your M-Pesa balance.

```dart
class MpesaBalance extends StatefulWidget {
  @override
  State<MpesaBalance> createState() => _MpesaBalanceState();
}
class _MpesaBalanceState extends State<MpesaBalance> {
  double _balance = 0;
  @override
  Widget build(BuildContext context) => ElevatedButton(
    onPressed: () => setState(() => _balance = 5000),
    child: Text('Balance: KES ${_balance.toStringAsFixed(2)}'),
  );
}
```

> **Kenya example:** The KRA iTax portal uses stateful forms —
> fields update as you fill in your PIN, income, and tax bracket.
''',
      },

      // WEEK 4 ───────────────────────────────────────────────────────────────
      {
        'id':'week4_l1','course_id':'week4',
        'title':'SQLite — Offline Data Storage',
        'read_minutes':4,'progress':0.0,
        'ai_summary':
        'SQLite stores data as a file on the device. '
            'Like a digital ledger at a kiosk — no internet needed.',
        'content':'''
## SQLite in Flutter

SQLite is a full database engine stored as a single `.db` file on the phone.
**No internet, no server** — perfect for offline apps used across Kenya
where connectivity is inconsistent.

### Real-world parallel
Think of a *mama mboga* keeping her stock list in a notebook. SQLite is that
notebook — always with you, no network required.

### Setup
```yaml
# pubspec.yaml
sqflite: ^2.3.3
path: ^1.9.0
```

### Open the database
```dart
final db = await openDatabase(
  join(await getDatabasesPath(), 'biashara.db'),
  version: 1,
  onCreate: (db, v) async {
    await db.execute(
      "CREATE TABLE stock (id INTEGER PRIMARY KEY, item TEXT, qty INTEGER)"
    );
  },
);
```

### CRUD
```dart
// CREATE
await db.insert('stock', {'item': 'Sukari', 'qty': 50});
// READ
final rows = await db.query('stock');
// UPDATE
await db.update('stock', {'qty': 45}, where: 'item=?', whereArgs: ['Sukari']);
// DELETE
await db.delete('stock', where: 'item=?', whereArgs: ['Sukari']);
```

> **Kenya case study:** The eCitizen app uses local SQLite caching so
> Kenyans can fill forms offline in areas with poor coverage like
> Turkana or Marsabit, then submit when back online.
''',
      },

      // WEEK 5 ───────────────────────────────────────────────────────────────
      {
        'id':'week5_l1','course_id':'week5',
        'title':'REST APIs & HTTP in Flutter',
        'read_minutes':4,'progress':0.0,
        'ai_summary':
        'HTTP GET fetches data. HTTP POST sends data. '
            'Like calling Safaricom customer care — you request, they respond.',
        'content':'''
## REST APIs in Flutter

A REST API is a web service you talk to over HTTP.
Every time you check your M-Pesa statement, Safaricom's app
calls a REST API to fetch your transactions.

### Add the package
```yaml
http: ^1.2.2
```

### GET request — fetch data
```dart
import 'package:http/http.dart' as http;
import 'dart:convert';

// Fetch Kenya counties from a public API
final res = await http.get(
  Uri.parse('https://jsonplaceholder.typicode.com/users'),
);
if (res.statusCode == 200) {
  final List data = jsonDecode(res.body);
  print('Fetched \${data.length} records');
}
```

### POST request — send data
```dart
final res = await http.post(
  Uri.parse('https://api.example.co.ke/feedback'),
  headers: {'content-type': 'application/json'},
  body: jsonEncode({'message': 'Great app!', 'county': 'Nairobi'}),
);
```

### Always handle errors
```dart
try {
  final res = await http.get(uri).timeout(Duration(seconds: 10));
  if (res.statusCode == 200) { /* success */ }
} catch (e) {
  // Handle: no internet (common in rural Kenya)
} finally {
  setState(() => _loading = false);
}
```

> **Kenya example:** The Huduma Number portal uses REST APIs to cross-check
> citizen data across NTSA, NHIF, and KRA databases in real time.
''',
      },

      // PHP ───────────────────────────────────────────────────────────────────
      {
        'id':'php_l1','course_id':'php',
        'title':'PHP Basics — Kenya Web Context',
        'read_minutes':5,'progress':0.0,
        'ai_summary':
        'PHP runs on the server and generates web pages. '
            'Most Kenyan government websites like eCitizen run on PHP.',
        'content':'''
## Introduction to PHP

PHP (Hypertext Preprocessor) is a server-side scripting language
used to build dynamic websites. It runs on the **server**, not the browser.

### Why PHP matters in Kenya
- **eCitizen** (ecitizen.go.ke) — built on PHP/Laravel
- **KRA iTax** — PHP backend
- Most Kenyan SACCO and microfinance web portals use PHP
- Cheap hosting on Kenyan providers (Safaricom Cloud, Truehost Kenya)

### Hello World
```php
<?php
  echo "Habari, Kenya!";
?>
```

### Variables & Data Types
```php
<?php
  $county   = "Nairobi";       // String
  $counties = 47;              // Integer
  $tax_rate = 0.16;            // Float (VAT in Kenya)
  $is_citizen = true;          // Boolean

  echo "Kenya has $counties counties.";
?>
```

### If / Else — M-Pesa tier example
```php
<?php
  $amount = 5000; // KES

  if ($amount <= 1000) {
    echo "Charge: KES 0 (Free tier)";
  } elseif ($amount <= 10000) {
    echo "Charge: KES 45 (M-Pesa tier 2)";
  } else {
    echo "Charge: KES 95 (M-Pesa tier 3)";
  }
?>
```

### Loops — listing Kenya counties
```php
<?php
  $counties = ["Nairobi", "Mombasa", "Kisumu", "Nakuru", "Eldoret"];

  foreach ($counties as $county) {
    echo "<li>$county County</li>";
  }
?>
```

### Functions — calculate KRA tax
```php
<?php
  function calculatePAYE(float $gross): float {
    // Kenya PAYE 2024 — simplified
    if ($gross <= 24000) return $gross * 0.10;
    if ($gross <= 32333) return 2400 + ($gross - 24000) * 0.25;
    return 4483 + ($gross - 32333) * 0.30;
  }

  $salary = 50000;
  $tax = calculatePAYE($salary);
  echo "PAYE on KES $salary = KES $tax";
?>
```

### PHP & MySQL (CRUD) — Student records
```php
<?php
  $conn = new mysqli("localhost", "root", "", "university_db");

  // CREATE
  $sql = "INSERT INTO students (name, reg_no) VALUES ('Wanjiku', 'STU001')";
  $conn->query($sql);

  // READ
  $result = $conn->query("SELECT * FROM students");
  while ($row = $result->fetch_assoc()) {
    echo $row['name'] . " — " . $row['reg_no'];
  }
?>
```

> **Kenya project idea:** Build a PHP system for a local *chama*
> (investment group) to track contributions, loans, and dividends.
> M-Pesa STK Push integration via Safaricom Daraja API.
''',
      },

      {
        'id':'php_l2','course_id':'php',
        'title':'PHP Forms & Daraja API',
        'read_minutes':5,'progress':0.0,
        'ai_summary':
        'PHP forms collect user input. '
            'Safaricom Daraja API lets you trigger M-Pesa payments from PHP.',
        'content':'''
## PHP Forms & M-Pesa Daraja API

### HTML Form + PHP processing
```php
<!-- form.html -->
<form method="POST" action="pay.php">
  <input type="text"   name="phone"  placeholder="07XXXXXXXX">
  <input type="number" name="amount" placeholder="Amount (KES)">
  <button type="submit">Pay via M-Pesa</button>
</form>
```

```php
<?php
// pay.php — process the form
if ($_SERVER['REQUEST_METHOD'] === 'POST') {
  $phone  = htmlspecialchars($_POST['phone']);
  $amount = (int) $_POST['amount'];

  // Validate Kenyan phone number
  if (!preg_match('/^07[0-9]{8}/', $phone)) {
    die("Invalid phone number. Use format 07XXXXXXXX");
  }
  if ($amount < 1 || $amount > 150000) {
    die("Amount must be between KES 1 and KES 150,000");
  }

  echo "Initiating M-Pesa STK Push to $phone for KES $amount...";
  // Call Daraja API here
}
?>
```

### Safaricom Daraja API — STK Push (simplified)
```php
<?php
function getMpesaToken(): string {
  $key    = 'YOUR_CONSUMER_KEY';
  $secret = 'YOUR_CONSUMER_SECRET';
  $credentials = base64_encode("$key:$secret");

  $ch = curl_init('https://sandbox.safaricom.co.ke/oauth/v1/generate?grant_type=client_credentials');
  curl_setopt($ch, CURLOPT_HTTPHEADER, ["Authorization: Basic $credentials"]);
  curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
  $res  = curl_exec($ch);
  $data = json_decode($res, true);
  return $data['access_token'];
}

function stkPush(string $phone, int $amount): array {
  $token     = getMpesaToken();
  $timestamp = date('YmdHis');
  $shortcode = '174379'; // Safaricom sandbox
  $passkey   = 'YOUR_PASSKEY';
  $password  = base64_encode($shortcode . $passkey . $timestamp);

  $payload = [
    'BusinessShortCode' => $shortcode,
    'Password'          => $password,
    'Timestamp'         => $timestamp,
    'TransactionType'   => 'CustomerPayBillOnline',
    'Amount'            => $amount,
    'PartyA'            => "254" . substr($phone, 1),
    'PartyB'            => $shortcode,
    'PhoneNumber'       => "254" . substr($phone, 1),
    'CallBackURL'       => 'https://yourapp.co.ke/callback',
    'AccountReference'  => 'LearnAI',
    'TransactionDesc'   => 'Course payment',
  ];

  $ch = curl_init('https://sandbox.safaricom.co.ke/mpesa/stkpush/v1/processrequest');
  curl_setopt($ch, CURLOPT_POST, true);
  curl_setopt($ch, CURLOPT_POSTFIELDS, json_encode($payload));
  curl_setopt($ch, CURLOPT_HTTPHEADER, [
    "Authorization: Bearer $token",
    "Content-Type: application/json",
  ]);
  curl_setopt($ch, CURLOPT_RETURNTRANSFER, true);
  return json_decode(curl_exec($ch), true);
}

// Trigger payment
$result = stkPush('0712345678', 500);
echo $result['ResponseDescription'];
?>
```
''',
      },

      // PYTHON ────────────────────────────────────────────────────────────────
      {
        'id':'python_l1','course_id':'python',
        'title':'Python Basics — Kenyan Context',
        'read_minutes':5,'progress':0.0,
        'ai_summary':
        'Python is readable and powerful. '
            'Used at Safaricom, Andela, and Kenya\'s top universities for data analysis.',
        'content':'''
## Introduction to Python

Python is one of the most readable programming languages.
It is used extensively in **data analysis, AI, web backends, and automation**.

### Why Python in Kenya
- **Safaricom** uses Python for data pipeline analytics
- **Andela** (major Kenya tech employer) tests Python in hiring
- **KPLC** and **KenGen** use Python for energy data modelling
- Python powers the machine learning models at iHub Nairobi

### Hello World
```python
print("Habari, Kenya!")
```

### Variables
```python
county     = "Mombasa"        # str
population = 1_208_333        # int (Mombasa county)
gdp_usd    = 98.8e9           # float (Kenya GDP)
is_eac     = True             # bool

print(f"{county} population: {population:,}")
```

### M-Pesa transaction analysis
```python
transactions = [1500, 200, 45000, 300, 800, 12000, 950]

total   = sum(transactions)
average = total / len(transactions)
highest = max(transactions)

print(f"Total transactions: KES {total:,}")
print(f"Average: KES {average:,.2f}")
print(f"Highest: KES {highest:,}")
```

### Functions — county tax calculator
```python
def calculate_county_levy(business_type: str, revenue: float) -> float:
    """Calculate Nairobi county single business permit fee."""
    rates = {
        "retail":      0.002,   # 0.2% of revenue
        "restaurant":  0.003,
        "tech":        0.001,
        "matatu":      15000,   # flat rate KES
    }
    rate = rates.get(business_type, 0.002)
    if isinstance(rate, float):
        return max(revenue * rate, 5000)  # minimum KES 5,000
    return rate

print(f"Tech company levy: KES {calculate_county_levy('tech', 2_000_000):,}")
print(f"Restaurant levy:   KES {calculate_county_levy('restaurant', 500_000):,}")
```

### Lists and loops — 47 counties
```python
counties = ["Nairobi", "Mombasa", "Kisumu", "Nakuru",
            "Uasin Gishu", "Meru", "Kakamega", "Kilifi"]

# Filter coastal counties
coastal = [c for c in counties if c in ["Mombasa", "Kilifi", "Kwale", "Lamu"]]
print(f"Coastal counties: {coastal}")

# Enumerate with numbering
for i, county in enumerate(counties, start=1):
    print(f"{i}. {county}")
```

### Dictionaries — student registry
```python
student = {
    "name":     "Kamau Njoroge",
    "reg_no":   "BIT/2021/001",
    "county":   "Kiambu",
    "course":   "BIT4107",
    "grade":    None,
}

# Add a grade
student["grade"] = "A"

# Destructure
name, course = student["name"], student["course"]
print(f"{name} is taking {course}")
```

> **Kenya project idea:** Use Python + pandas to analyse KNBS census data.
> Plot population density per county using matplotlib.
''',
      },

      {
        'id':'python_l2','course_id':'python',
        'title':'Python Data Analysis — KNBS Case Study',
        'read_minutes':5,'progress':0.0,
        'ai_summary':
        'Python pandas and matplotlib are used to analyse '
            'real Kenyan census and economic data from KNBS.',
        'content':'''
## Python Data Analysis — Kenya National Bureau of Statistics

### Install libraries
```bash
pip install pandas matplotlib requests
```

### Analysing Kenya county populations (KNBS 2019 Census)
```python
import pandas as pd
import matplotlib.pyplot as plt

# Kenya top counties by population (KNBS 2019)
data = {
    "County":     ["Nairobi","Kiambu","Nakuru","Kakamega",
                   "Bungoma","Meru","Kilifi","Machakos"],
    "Population": [4_397_073, 2_417_735, 2_162_202, 1_867_579,
                   1_670_570, 1_545_714, 1_453_787, 1_421_932],
    "Area_km2":   [696, 2449, 7495, 3250, 3032, 6930, 12610, 5953],
}

df = pd.DataFrame(data)
df["Density"] = (df["Population"] / df["Area_km2"]).round(1)

print(df.sort_values("Density", ascending=False).to_string(index=False))
```

### Web scraping — KRA exchange rates
```python
import requests
from datetime import date

def get_kra_rate(currency: str = "USD") -> float:
    """Fetch KRA daily exchange rate (for tax computations)."""
    url = f"https://api.exchangerate-api.com/v4/latest/KES"
    try:
        res = requests.get(url, timeout=5)
        rates = res.json()["rates"]
        return round(1 / rates.get(currency, 1), 2)
    except Exception:
        return 129.50  # fallback rate

usd_rate = get_kra_rate("USD")
print(f"Today ({date.today()}) KRA Rate: 1 USD = KES {usd_rate}")
```

### File handling — M-Pesa statement parser
```python
import csv

# Imagine an M-Pesa statement exported as CSV
def parse_mpesa_statement(filepath: str) -> dict:
    totals = {"sent": 0, "received": 0, "withdrawn": 0}
    with open(filepath, newline="") as f:
        reader = csv.DictReader(f)
        for row in reader:
            txn_type = row.get("Type", "")
            amount   = float(row.get("Amount", 0))
            if "Sent"      in txn_type: totals["sent"]      += amount
            elif "Received" in txn_type: totals["received"]  += amount
            elif "Withdraw" in txn_type: totals["withdrawn"] += amount
    return totals

# summary = parse_mpesa_statement("statement.csv")
# print(summary)
```

### OOP — Chama (investment group) management
```python
class Chama:
    def __init__(self, name: str, members: list[str]):
        self.name    = name
        self.members = members
        self.kitty   = 0.0

    def contribute(self, member: str, amount: float):
        if member not in self.members:
            raise ValueError(f"{member} is not a member of {self.name}")
        self.kitty += amount
        print(f"{member} contributed KES {amount:,}. Kitty: KES {self.kitty:,}")

    def lend(self, member: str, amount: float, interest: float = 0.10):
        if amount > self.kitty:
            raise ValueError("Insufficient funds in kitty")
        self.kitty -= amount
        repayment = amount * (1 + interest)
        print(f"Loan: KES {amount:,} to {member}. Repay KES {repayment:,}")

# Demo
chama = Chama("Wekeza Pamoja", ["Wanjiku", "Otieno", "Kamau"])
chama.contribute("Wanjiku", 5000)
chama.contribute("Otieno",  5000)
chama.lend("Kamau", 3000)
```
''',
      },

      // NETWORKS ────────────────────────────────────────────────────────────
      {
        'id':'networks_l1','course_id':'networks',
        'title':'Computer Networks — Kenya Infrastructure',
        'read_minutes':5,'progress':0.0,
        'ai_summary':
        'Networks connect computers. Kenya has the TEAMS and EASSy '
            'undersea cables landing at Mombasa connecting Africa to the world.',
        'content':'''
## Computer Networks — Kenya Context

### What is a computer network?
A computer network is a group of interconnected devices that share
resources and communicate using agreed protocols.

### Kenya's internet infrastructure
| Infrastructure | Detail |
|---|---|
| **TEAMS cable** | East Africa Marine System — lands at Mombasa; links Kenya to UAE |
| **EASSy cable** | East Africa Submarine System — Mombasa to Europe via South Africa |
| **SEACOM** | Mombasa to India and Europe — used by many ISPs |
| **IXP Nairobi** | Kenya Internet Exchange Point — routes local traffic locally (faster) |
| **KIXP** | Keeps Safaricom ↔ Airtel ↔ Telkom traffic within Kenya |

### Network types
```
PAN  — Bluetooth between your phone and earbuds (range: ~10 m)
LAN  — University computer lab (range: building)
MAN  — Nairobi city fibre network (range: city)
WAN  — Safaricom backbone connecting Nairobi to Kisumu (range: country)
Internet — Global network connecting Kenya to the world
```

### OSI Model — with Kenya examples
```
Layer 7 — Application   → M-Pesa app, Chrome browser
Layer 6 — Presentation  → SSL encryption on eCitizen (HTTPS)
Layer 5 — Session       → Your login session on KRA iTax
Layer 4 — Transport     → TCP (reliable) for web, UDP for M-Pesa USSD
Layer 3 — Network       → IP address routing Nairobi → Mombasa
Layer 2 — Data Link     → MAC addresses on Safaricom fibre switches
Layer 1 — Physical      → TEAMS undersea cable fibre optic
```

### IP Addressing
```
IPv4 example:  197.248.1.5   (common in Kenya ISP allocations)
Subnet mask:   255.255.255.0
Gateway:       197.248.1.1   (your router)
DNS:           8.8.8.8       (Google) or 1.1.1.1 (Cloudflare)

CIDR notation: 197.248.1.0/24 — 254 usable hosts
```

### Safaricom network — how a call works
```
1. Your phone → Safaricom BTS tower (4G LTE signal)
2. BTS → Safaricom BSC (Base Station Controller) via fibre
3. BSC → Core network (Safaricom HQ, Westlands Nairobi)
4. Core → Routes to recipient's network (Airtel, Telkom)
5. Airtel BSC → Recipient's phone
```

> **Kenya fact:** As of 2024, Kenya has 39.8 million internet users
> (KNBS) — 75% access via mobile. Safaricom holds 65% market share
> making it East Africa's largest telco.
''',
      },

      {
        'id':'networks_l2','course_id':'networks',
        'title':'TCP/IP, DNS & Security — Kenyan Cases',
        'read_minutes':5,'progress':0.0,
        'ai_summary':
        'TCP/IP is the protocol suite powering the internet. '
            'DNS translates names to IPs. HTTPS secures eCitizen and M-Pesa.',
        'content':'''
## TCP/IP, DNS & Network Security

### TCP vs UDP
```
TCP (Transmission Control Protocol)
  ✓ Reliable — guarantees delivery
  ✓ Ordered — packets arrive in sequence
  ✗ Slower
  Use: eCitizen file upload, KRA tax submission, email

UDP (User Datagram Protocol)
  ✗ No guarantee of delivery
  ✓ Very fast — no handshake
  Use: M-Pesa USSD (*334#), live sports streaming, VoIP calls
```

### Three-way TCP handshake
```
Client (Nairobi)          Server (ecitizen.go.ke)
     |                           |
     |------- SYN ------------->|   "I want to connect"
     |<------ SYN-ACK ----------|   "OK, confirmed"
     |------- ACK ------------->|   "Great, let us talk"
     |====== DATA EXCHANGE ======|
```

### DNS — Domain Name System
DNS is like the phonebook of the internet. You type a name;
DNS returns the IP address.

```
You type:   www.safaricom.co.ke
DNS lookup: 197.248.4.154  (Safaricom's IP)
Browser connects to: 197.248.4.154:443 (HTTPS)
```

**Kenya DNS facts:**
- `.co.ke` domains managed by KENIC (Kenya Network Information Centre)
- KICTANet oversees Kenya internet governance
- Root DNS servers (13 globally) are queried through local resolvers

### HTTPS & SSL — how eCitizen stays secure
```
1. Browser requests https://ecitizen.go.ke
2. Server sends SSL certificate (issued by a CA like DigiCert)
3. Browser verifies certificate is valid and not expired
4. Symmetric encryption key exchanged (TLS handshake)
5. All data encrypted — your Huduma Number safe in transit
```

### Common network attacks & Kenya examples
```
Phishing      → Fake "Safaricom" SMS asking for M-Pesa PIN
               → "KRA Tax Refund" scam emails
               → Always check sender: @safaricom.co.ke not @gmail.com

DDoS          → 2022: Several Kenyan bank websites knocked offline
               → Saturates server with millions of fake requests

Man-in-Middle → Public WiFi at Nairobi CBD cafes intercepts traffic
               → Solution: Use VPN + only visit HTTPS sites

SQL Injection → Attacker sends SQL in a web form field
               → Input: "'; DROP TABLE users; --"
               → Solution: Use prepared statements (same as PDO in PHP)
```

### Subnetting exercise — Nairobi University campus
```
University needs 5 departments:
  Admin:    30 hosts  → /27 (subnet: 192.168.1.0/27,  30 hosts)
  Library:  50 hosts  → /26 (subnet: 192.168.1.64/26, 62 hosts)
  ICT Lab:  60 hosts  → /26 (subnet: 192.168.1.128/26,62 hosts)
  Hostels: 100 hosts  → /25 (subnet: 192.168.1.0/25, 126 hosts)
  WiFi:    200 hosts  → /24 (subnet: 192.168.2.0/24, 254 hosts)
```

> **Kenya fact:** The Konza Technopolis (Silicon Savannah) smart city
> 60 km from Nairobi is designed with a fibre backbone to every building,
> 1 Gbps internet, and a dedicated data centre for government cloud services.
''',
      },
    ];

    for (final l in lessons) await _db!.insert('lessons', l);

    // Default progress stats
    await _db!.insert('user_progress', {'key':'streak','value':'3'});
    await _db!.insert('user_progress', {'key':'lessons_done','value':'6'});
    await _db!.insert('user_progress', {'key':'quiz_avg','value':'82'});
  }

  // ── USER CRUD ─────────────────────────────────────────────────────────────

  /// Registers a new user. Returns false if email already taken.
  Future<bool> registerUser(
      String name, String email, String password) async {
    try {
      await _db!.insert('users', {
        'name':       name,
        'email':      email,
        'password':   password, // hash in production!
        'level':      0,
        'created_at': DateTime.now().toIso8601String(),
      });
      await logActivity(email, 'REGISTER', 'New account created');
      return true;
    } catch (_) {
      return false; // email duplicate
    }
  }

  /// Validates login credentials. Returns user map or null.
  Future<Map<String, dynamic>?> loginUser(
      String email, String password) async {
    final rows = await _db!.query('users',
        where: 'email = ? AND password = ?',
        whereArgs: [email, password],
        limit: 1);
    if (rows.isEmpty) return null;
    await logActivity(email, 'LOGIN', 'Signed in');
    return rows.first;
  }

  /// Returns all registered users.
  Future<List<Map<String, dynamic>>> getAllUsers() =>
      _db!.query('users', orderBy: 'created_at DESC');

  // ── ACTIVITY LOG ──────────────────────────────────────────────────────────

  /// Records a user action in the activity log.
  Future<void> logActivity(
      String email, String action, [String? detail]) =>
      _db!.insert('user_activity', {
        'user_email':  email,
        'action':      action,
        'detail':      detail,
        'occurred_at': DateTime.now().toIso8601String(),
      });

  /// Returns recent activity for a user (newest first).
  Future<List<Map<String, dynamic>>> getUserActivity(
      String email, {int limit = 20}) =>
      _db!.query('user_activity',
          where: 'user_email = ?',
          whereArgs: [email],
          orderBy: 'occurred_at DESC',
          limit: limit);

  /// Returns all activity across all users (admin view).
  Future<List<Map<String, dynamic>>> getAllActivity({int limit = 50}) =>
      _db!.rawQuery(
          '''SELECT ua.*, u.name as user_name
           FROM user_activity ua
           LEFT JOIN users u ON ua.user_email = u.email
           ORDER BY ua.occurred_at DESC
           LIMIT ?''',
          [limit]);

  // ── COURSES ───────────────────────────────────────────────────────────────

  Future<List<Course>> getCourses() async {
    final rows = await _db!.query('courses', orderBy: 'id ASC');
    return rows.map(Course.fromMap).toList();
  }

  Future<int> insertCourse(Course c) => _db!.insert(
      'courses', c.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace);

  Future<void> updateCourse(Course c) => _db!.update(
      'courses', c.toMap(), where: 'id = ?', whereArgs: [c.id]);

  Future<void> deleteCourse(String id) =>
      _db!.delete('courses', where: 'id = ?', whereArgs: [id]);

  // ── LESSONS ───────────────────────────────────────────────────────────────

  Future<Lesson?> getLesson(String courseId) async {
    final rows = await _db!.query('lessons',
        where: 'course_id = ?', whereArgs: [courseId], limit: 1);
    if (rows.isEmpty) return null;
    final r = rows.first;
    return Lesson(
        id: r['id'] as String, title: r['title'] as String,
        subtitle: courseId, content: r['content'] as String,
        aiSummary: r['ai_summary'] as String,
        readMinutes: r['read_minutes'] as int,
        progress: (r['progress'] as num).toDouble());
  }

  Future<void> saveProgress(String lessonId, double progress) =>
      _db!.update('lessons', {'progress': progress},
          where: 'id = ?', whereArgs: [lessonId]);

  // ── QUIZ ATTEMPTS ─────────────────────────────────────────────────────────

  Future<void> saveQuizAttempt(
      String lessonId, int score, String email) =>
      _db!.insert('quiz_attempts', {
        'lesson_id':    lessonId,
        'user_email':   email,
        'score':        score,
        'attempted_at': DateTime.now().toIso8601String(),
      });

  Future<List<Map<String, dynamic>>> getQuizHistory(String email) =>
      _db!.rawQuery(
          '''SELECT qa.*, l.title as lesson_title
           FROM quiz_attempts qa
           LEFT JOIN lessons l ON qa.lesson_id = l.id
           WHERE qa.user_email = ?
           ORDER BY qa.attempted_at DESC''',
          [email]);

  Future<void> deleteQuizAttempt(int id) =>
      _db!.delete('quiz_attempts', where: 'id = ?', whereArgs: [id]);

  // ── USER PROGRESS ─────────────────────────────────────────────────────────

  Future<Map<String, String>> getUserProgress() async {
    final rows = await _db!.query('user_progress');
    return {for (final r in rows)
      r['key'] as String: r['value'] as String};
  }

  Future<void> setUserProgress(String key, String value) =>
      _db!.insert('user_progress', {'key': key, 'value': value},
          conflictAlgorithm: ConflictAlgorithm.replace);

  Future<void> clearAllQuizHistory(String email) =>
      _db!.delete('quiz_attempts', where: 'user_email = ?', whereArgs: [email]);
}

class _POST {
}

class _SERVER {
}