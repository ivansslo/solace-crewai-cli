import os, sys

# Force Groq as LLM provider
os.environ["OPENAI_API_KEY"] = os.environ.get("GROQ_API_KEY", "")

from crewai import Agent, Crew, Process, Task, LLM

llm = LLM(
    model="groq/llama-3.3-70b-versatile",
    api_key=os.environ.get("GROQ_API_KEY", ""),
)

researcher = Agent(
    role="Research Specialist",
    goal="Find accurate information on any topic",
    backstory="Expert researcher. Part of Solace Hermes AI Hub.",
    llm=llm, verbose=True, allow_delegation=False,
)
analyst = Agent(
    role="Data Analyst",
    goal="Analyze findings and extract insights",
    backstory="Skilled analyst who finds patterns.",
    llm=llm, verbose=True, allow_delegation=False,
)
writer = Agent(
    role="Content Writer",
    goal="Create clear reports from research",
    backstory="Professional writer for concise content.",
    llm=llm, verbose=True, allow_delegation=False,
)

def run_crew(topic):
    t1 = Task(description="Research: " + topic, expected_output="Research summary", agent=researcher)
    t2 = Task(description="Analyze: " + topic, expected_output="Analysis with insights", agent=analyst)
    t3 = Task(description="Write report: " + topic, expected_output="Report in markdown", agent=writer)
    return str(Crew(agents=[researcher, analyst, writer], tasks=[t1, t2, t3], process=Process.sequential, verbose=True).kickoff())

if __name__ == "__main__":
    topic = " ".join(sys.argv[1:]) or "AI agents in 2026"
    print(run_crew(topic))
