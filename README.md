# 🤖 LangChain Customer Support Agent

> **Learn LangChain by building a real-world AI-powered customer support agent!**

An **educational project** demonstrating how to build a production-ready customer support system using **LangChain tools**, **OpenAI GPT-3.5**, and **Streamlit**. Perfect for learning LangChain fundamentals, AI tool development, and full-stack deployment.

**Keywords**: LangChain, OpenAI, Customer Support AI, Streamlit, Ticket Classification, AI Agent, Python Tutorial, AWS Deployment, Docker

---

## 🎯 What is This Project?

This is an **educational project** designed to teach you:

- **LangChain Fundamentals**: How to use LangChain tools, prompts, and chains
- **AI Tool Development**: Building custom tools that use LLMs
- **Real-World Application**: Creating a production-ready customer support system
- **Full-Stack Deployment**: From local development to AWS cloud deployment

### What Does It Do?

The application automatically:
1. **Classifies** customer support tickets into categories (refund, technical, billing, general)
2. **Generates** professional, empathetic responses
3. **Processes** refund requests by extracting order IDs
4. **Saves** everything to a database for tracking

All powered by **LangChain tools** and **OpenAI's GPT-3.5**!

---

## 🎓 Educational Value

### What You'll Learn

✅ **LangChain Tools**: Create custom tools using the `@tool` decorator  
✅ **LLM Integration**: Connect with OpenAI's API using LangChain  
✅ **Prompt Engineering**: Design effective prompts for classification and generation  
✅ **Database Integration**: Save and retrieve data from PostgreSQL/Supabase  
✅ **Streamlit UI**: Build interactive web applications  
✅ **Docker**: Containerize your application  
✅ **AWS Deployment**: Deploy to production using App Runner  

### Perfect For

- 🎓 **Students** learning AI/ML development
- 👨‍💻 **Developers** new to LangChain
- 🏢 **Teams** wanting to understand AI tooling
- 🚀 **Builders** creating their first AI application

---

## 🚀 Quick Start (Choose Your Path)

### Path 1: Local Development (Recommended for Learning)

**Best for**: Understanding how everything works, experimenting, and learning.

#### Step 1: Install Dependencies

```bash
# Install uv (fast Python package manager)
curl -LsSf https://astral.sh/uv/install.sh | sh

# Install project dependencies
uv pip install -e .
```

#### Step 2: Set Up Credentials

```powershell
# Copy the example file
copy env.example .env

# Edit .env and add your OpenAI API key
# Get one from: https://platform.openai.com/api-keys
```

Your `.env` file should look like:
```env
OPENAI_API_KEY=sk-proj-your-key-here

# Database is optional - app works without it!
# DATABASE_URL=postgresql://user:password@host:port/database
```

#### Step 3: Run the Application

```bash
streamlit run app_langchain.py
```

**That's it!** 🎉 Open `http://localhost:8501` in your browser and start testing!

---

### Path 2: Docker (Recommended for Consistency)

**Best for**: Ensuring everyone has the same environment, or if you prefer containerized development.

#### Step 1: Set Up Credentials

```powershell
# Copy the example file
copy env.example .env

# Edit .env and add your credentials
```

#### Step 2: Run with Docker

```powershell
# Start the application
docker-compose up
```

**That's it!** 🎉 Open `http://localhost:8501` in your browser!

**What happens:**
- Docker builds the image automatically
- Loads your `.env` file
- Starts the Streamlit app
- Everything runs in an isolated container

---

### Path 3: AWS Deployment (Production Ready)

**Best for**: Deploying to production, sharing with others, or learning cloud deployment.

#### Prerequisites

1. **AWS Account** (free tier works!)
2. **AWS CLI installed** and configured
3. **Docker Desktop** running

#### Step 1: Configure AWS

```powershell
# Install AWS CLI (if not installed)
winget install Amazon.AWSCLI

# Configure your credentials
aws configure
# Enter: Access Key ID, Secret Access Key, Region (ap-south-1), Output (json)
```

#### Step 2: Set Up Credentials

```powershell
# Copy the example file
copy env.example .env

# Edit .env and add your credentials
```

#### Step 3: Deploy!

```powershell
# One command deployment
.\deploy.ps1 app-runner
```

**That's it!** 🎉 The script will:
- Build your Docker image
- Push to AWS
- Deploy to App Runner
- Give you a live URL!

**For detailed AWS deployment instructions, see [DEPLOY.md](DEPLOY.md)**

---

## 📚 Understanding the Code

### Project Structure

```
customer-support-agent-v2/
├── app_langchain.py          # Main application (start here!)
├── config.py                 # Database configuration
├── pyproject.toml            # Dependencies
│
├── Dockerfile                # Docker configuration
├── docker-compose.yml        # Local Docker setup
├── deploy.ps1               # AWS deployment script
│
├── database_setup.sql        # Database setup (optional)
├── .streamlit/
│   └── config.toml          # Streamlit settings
│
├── env.example              # Credentials template
└── README.md                # This file!
```

### Key Files Explained

**`app_langchain.py`** - The main application:
- Contains 3 LangChain tools: `triage_ticket`, `generate_response`, `process_refund_request`
- Streamlit UI for submitting tickets
- Database integration for saving results

**`config.py`** - Database configuration:
- Handles both Supabase and direct PostgreSQL connections
- Gracefully falls back if no database is configured

**`database_setup.sql`** - Database schema:
- Creates the `tickets` table
- Includes optional test data
- Works with PostgreSQL and Supabase

---

## 🛠️ Features

### Three LangChain Tools

1. **🔍 Triage Tool** (`triage_ticket`)
   - Classifies tickets into: refund, technical, billing, or general
   - Uses GPT-3.5 to understand ticket content

2. **✍️ Response Tool** (`generate_response`)
   - Generates professional, empathetic customer support responses
   - Tailored to the ticket category

3. **💰 Refund Tool** (`process_refund_request`)
   - Extracts order IDs from tickets
   - Checks refund eligibility (demo mode with mock orders)

### UI Features

- ✅ Clean, intuitive ticket submission form
- ✅ Instant classification results
- ✅ Generated draft responses
- ✅ Automatic refund processing
- ✅ Recent tickets history (if database configured)
- ✅ System metrics and statistics

---

## 🗄️ Database Setup (Optional)

The app works perfectly **without a database**! But if you want to save tickets:

### For Local PostgreSQL

```powershell
# Run the SQL script
psql -h localhost -U postgres -d your_database -f database_setup.sql
```

### For Supabase

1. Go to [Supabase Dashboard](https://app.supabase.com)
2. Select your project → **SQL Editor** → **New Query**
3. Copy and paste `database_setup.sql`
4. Click **Run**

### Test Data

The SQL script includes 8 sample tickets (commented out). Uncomment the `INSERT INTO tickets` section to add them!

---

## 📦 Dependencies

All managed by `uv` in `pyproject.toml`:

- **Core**: streamlit, pandas, python-dotenv
- **LangChain**: langchain, langchain-openai, langchain-community, langchain-core
- **Database**: psycopg2-binary, sqlalchemy, supabase

**Total: 10 packages** - lightweight and focused!

---

## 🧪 Testing the Application

### Try These Test Cases

**Refund Request:**
```
Subject: Product damaged
Body: Order ORD123 arrived broken, need refund
→ Should classify as "refund" and process refund
```

**Technical Issue:**
```
Subject: Can't login
Body: Password reset not working
→ Should classify as "technical" and generate support response
```

**Billing Question:**
```
Subject: Charged twice
Body: I was charged twice this month for subscription
→ Should classify as "billing" and generate response
```

**General Inquiry:**
```
Subject: Feature request
Body: Can you add dark mode?
→ Should classify as "general" and generate response
```

### Mock Orders (Built-in)

The app includes these test orders:
- `ORD123` - Laptop ($99.99)
- `ORD456` - Mouse ($49.99)
- `ORD789` - Monitor ($149.99)
- `ORD101` - Keyboard ($299.99)
- `ORD202` - Webcam ($199.99)

Use these in refund requests to test the refund tool!

---

## 🔧 Troubleshooting

### "No module named langchain_openai"

```bash
# Reinstall dependencies
uv pip install -e .
```

### "OPENAI_API_KEY not found"

- Check `.env` file exists in project root
- Verify `OPENAI_API_KEY=sk-proj-...` is in `.env`
- Restart the app

### "Database connection failed"

- Check `DATABASE_URL` in `.env` (if using database)
- Verify connection string is correct
- **Good news**: App works without database! This is optional.

### Docker Issues

- Ensure Docker Desktop is running
- Check `.env` file is in same folder as `docker-compose.yml`
- Try: `docker-compose down` then `docker-compose up --build`

### AWS Deployment Issues

- Verify AWS CLI is configured: `aws configure`
- Check AWS credentials have permissions for ECR and App Runner
- See [DEPLOY.md](DEPLOY.md) for detailed troubleshooting

---

## 📖 Learning Resources

### LangChain Documentation
- [LangChain Tools](https://python.langchain.com/docs/modules/tools/)
- [LangChain OpenAI Integration](https://python.langchain.com/docs/integrations/llms/openai)

### Project-Specific Learning

**Understanding the Tools:**
1. Open `app_langchain.py`
2. Find the `@tool` decorators (lines 57, 84, 106)
3. See how each tool uses the LLM
4. Experiment by modifying prompts!

**Understanding the Flow:**
1. User submits ticket → `triage_ticket` classifies it
2. Category determined → `generate_response` creates reply
3. If refund → `process_refund_request` processes it
4. Everything saved to database (if configured)

---

## 🎯 Next Steps

### For Learning

1. **Modify the prompts** in each tool - see how it changes behavior
2. **Add a new tool** - maybe a sentiment analysis tool?
3. **Experiment with different models** - try GPT-4 or other models
4. **Customize the UI** - make it your own!

### For Production

1. **Add authentication** - protect your app
2. **Improve error handling** - make it more robust
3. **Add logging** - track usage and errors
4. **Scale the database** - optimize queries

---

## 🤝 Contributing

This is an educational project! Feel free to:
- Fork and experiment
- Share your improvements
- Report issues
- Suggest new features

---

## 📄 License

This project is for educational purposes. Feel free to use, modify, and learn from it!

---

## 💡 Tips for Success

1. **Start Simple**: Run locally first, understand how it works
2. **Read the Code**: The code is well-commented - read it!
3. **Experiment**: Change prompts, add features, break things (then fix them!)
4. **Use Docker**: Once comfortable, try Docker for consistency
5. **Deploy**: Finally, deploy to AWS to see it live!

---

## 🎉 You're Ready!

Choose your path above and start building! Remember:
- **Learning is the goal** - don't worry about perfection
- **Experimentation is encouraged** - break things and learn
- **Questions are welcome** - check the code, it's well-documented

**Happy Learning! 🚀**

---

## 📊 Project Stats & Topics

**Technologies**: LangChain, OpenAI, Streamlit, Python, PostgreSQL, Supabase, Docker, AWS  
**Use Cases**: Customer Support, Ticket Classification, AI Agents, Response Generation  
**Learning**: LangChain Tutorial, AI Development, Full-Stack Deployment  
**Deployment**: Docker, AWS App Runner, Containerization

---

<div align="center">
  <small>Built with ❤️ for learning LangChain</small><br>
  <small>Future Proof India</small>
</div>
