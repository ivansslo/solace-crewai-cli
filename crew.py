import os, sys

key = os.environ.get("GROQ_API_KEY", "")
os.environ["OPENAI_API_KEY"] = key
os.environ["OPENAI_API_BASE"] = "https://api.groq.com/openai/v1"
os.environ["OPENAI_MODEL_NAME"] = "llama-3.3-70b-versatile"

from crewai import Agent, Crew, Process, Task

researcher = Agent(role="Research Specialist", goal="Find accurate, comprehensive information on any topic", backstory="Expert researcher with years of experience. Part of Solace Hermes AI Hub.", verbose=True, allow_delegation=False)
analyst = Agent(role="Data Analyst", goal="Analyze findings and extract actionable insights and patterns", backstory="Skilled analyst who finds patterns and provides clear recommendations.", verbose=True, allow_delegation=False)
writer = Agent(role="Content Writer", goal="Create clear, well-structured reports from research and analysis", backstory="Professional writer who creates concise, accurate content.", verbose=True, allow_delegation=False)

topic = " ".join(sys.argv[1:]) or "AI agents in 2026"
t1 = Task(description="Research thoroughly: " + topic + ". Find key facts, recent developments, and sources.", expected_output="Structured research summary with key findings and sources.", agent=researcher)
t2 = Task(description="Analyze the research findings about: " + topic + ". Identify patterns, draw conclusions.", expected_output="Analysis report with insights, conclusions, and recommendations.", agent=analyst)
t3 = Task(description="Write a comprehensive report about: " + topic + ". Combine research and analysis.", expected_output="Professional report (300-500 words) in clean markdown format.", agent=writer)
result = Crew(agents=[researcher, analyst, writer], tasks=[t1, t2, t3], process=Process.sequential, verbose=True).kickoff()
print(result)
