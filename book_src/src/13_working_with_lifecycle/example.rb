require 'gooddata'

TOKEN = 'token'
PASSWORD = 'pass'

client = GoodData.connect('mustang@gooddata.com', PASSWORD, server: 'https://mustangs.intgdc.com', verify_ssl: false )
domain = client.domain('mustangs')

seq_number = 8

# Prepare master project 
# ======================

# Create LDM blueprint
blueprint = GoodData::Model::ProjectBlueprint.build('HR Demo Project') do |p|
  p.add_date_dimension('dataset.payment', title: 'Payment')

  p.add_dataset('dataset.department', title: 'Department', folder: 'Department & Employee') do |d|
    d.add_anchor('attr.department.id', title: 'Department ID')
    d.add_label('label.department.id', reference:'attr.department.id', title: 'Department ID')
    d.add_label('label.department.name', reference: 'attr.department.id', title: 'Department Name')
    d.add_attribute('attr.department.region', title: 'Department Region')
    d.add_label('label.department.region', reference: 'attr.department.region', title: 'Department Region')
  end

  p.add_dataset('dataset.employee', title: 'Employee', folder: 'Department & Employee') do |d|
    d.add_anchor('attr.employee.id', title: 'Employee ID')
    d.add_label('label.employee.id', title: 'Employee ID', reference:'attr.employee.id')
    d.add_label('label.employee.fname', title: 'Employee Firstname', reference:'attr.employee.id')
    d.add_label('label.employee.lname', title: 'Employee Lastname', reference:'attr.employee.id')
    d.add_reference('dataset.department')
  end

  p.add_dataset('dataset.salary', title: 'Salary') do |d|
    d.add_anchor('attr.salary.id', title: 'Salary ID', folder: 'Salary')
    d.add_label('label.salary.id', reference:'attr.salary.id', title: 'Salary ID', folder: 'Salary')
    d.add_fact('fact.salary.amount', title: 'Amount', folder: 'Salary')
    d.add_date('dataset.payment', format: 'yyyy-MM-dd')
    d.add_reference('dataset.employee')
  end
end

# Create new project (datamart)
project = client.create_project_from_blueprint(blueprint, auth_token: TOKEN)
puts "Created project #{project.pid}"

# Load data
department_data = [
    ['label.department.id','label.department.name', 'label.department.region'],
    ['d1','HQ General Management', 'North America'],
    ['d2','HQ Information Systems', 'Europe']
]
project.upload(department_data, blueprint, 'dataset.department')

employee_data_with_dep = [
    ['label.employee.id','label.employee.fname','label.employee.lname','dataset.department', 'label.department.region'],
    ['e1','Sheri','Nowmer','d1', 'North America'],
    ['e2','Derrick','Whelply','d2', 'Europe']
]
project.upload(employee_data_with_dep, blueprint, 'dataset.employee')

salary_data = [
    ['label.salary.id','dataset.employee','fact.salary.amount','dataset.payment'],
    ['s1','e1','10230','2006-01-01'], ['s2','e2','4810','2006-01-01'], ['s617','e1','10230','2006-02-01'],
    ['s618','e2','4810','2006-02-01'], ['s1233','e1','10230','2006-03-01'], ['s1234','e2','4810','2006-03-01'],
    ['s1849','e1','10230','2006-04-01'], ['s1850','e2','4810','2006-04-01'], ['s2465','e1','10230','2006-05-01'],
    ['s2466','e2','4810','2006-05-01'], ['s3081','e1','10230','2006-06-01'], ['s3082','e2','4810','2006-06-01'],
    ['s3697','e1','10230','2006-07-01'], ['s3698','e2','4810','2006-07-01'], ['s4313','e1','10230','2006-08-01'],
    ['s4314','e2','4810','2006-08-01'], ['s4929','e1','10230','2006-09-01'], ['s4930','e2','4810','2006-09-01'],
    ['s5545','e1','10230','2006-10-01'], ['s5546','e2','4810','2006-10-01'], ['s6161','e1','10230','2006-11-01'],
    ['s6162','e2','4810','2006-11-01'], ['s6777','e1','10230','2006-12-01'], ['s6778','e2','4810','2006-12-01'],
    ['s7393','e1','10440','2007-01-01'], ['s7394','e2','5020','2007-01-01'], ['s8548','e1','10440','2007-02-01'],
    ['s8549','e2','5020','2007-02-01'], ['s9703','e1','10440','2007-03-01'], ['s9704','e2','5020','2007-03-01'],
    ['s10858','e1','10440','2007-04-01'], ['s10859','e2','5020','2007-04-01'], ['s12013','e1','10440','2007-05-01'],
    ['s12014','e2','5020','2007-05-01'], ['s13168','e1','10440','2007-06-01'], ['s13169','e2','5020','2007-06-01'],
    ['s14323','e1','10440','2007-07-01'], ['s14324','e2','5020','2007-07-01'], ['s15478','e1','10440','2007-08-01'],
    ['s15479','e2','5020','2007-08-01'], ['s16633','e1','10440','2007-09-01'], ['s16634','e2','5020','2007-09-01'],
    ['s17788','e1','10440','2007-10-01'], ['s17789','e2','5020','2007-10-01'], ['s18943','e1','10440','2007-11-01'],
    ['s18944','e2','5020','2007-11-01'], ['s20098','e1','10440','2007-12-01'], ['s20099','e2','5020','2007-12-01']
]
project.upload(salary_data, blueprint, 'dataset.salary')

# Report
metric = project.facts('fact.salary.amount').create_metric
metric.save
report = project.create_report(title: 'My report', left: ['label.department.name'], top: [metric])

dashboard = project.create_dashboard(:title => 'Test Dashboard')
tab = dashboard.create_tab(:title => 'Tab Title #1')
tab.title = 'Test #42'
item = tab.add_report_item(:report => report, :position_x => 10, :position_y => 20)
item.position_x = 400
item.position_y = 300
dashboard.lock
dashboard.save

# Prepare segment
# ===============

segment = domain.create_segment(segment_id: "segment_#{seq_number}", master_project: project)

# Make a Release
# ==============
segment.synchronize_clients


# Prepare client
# ==============
segment_client = segment.create_client(id: "client_#{seq_number}")


# Spin up project for the client
# ==============================
# 
# This way we do not think about it ourselves
domain.provision_client_projects

# Let's check that it worked
segment.clients.first.project.pid
# => aerkc6562oiauaof9mxtowcc4fl5vwb4
segment.clients.first.project.metrics.count
# => 1
segment.clients.first.project.dashboards.first.title
# => 'Test Dashboard'

# The client project should not have data from master
segment.master_project.metrics.first.execute
# => 0.366E6
segment.clients.first.project.metrics.first.execute
# => nil

# Update master and propagate changes
# ===================================

# Now let's pretend we want to change something in our master.
# Let's change a title in master and transfer to the clients
dashboard.title = 'Better Test Dashboard'
dashboard.save

# Make a release and synchronize clients
segment.synchronize_clients

# Check the results
segment.clients.first.project.dashboards.first.title
# => "Better Test Dashboard"

# Add additional clients
# ======================
# 
# This is it. Just for illustration let's create another client. This basically just means repeating the flow.
# We already have our master prepared so let's just create a new client.
another_segment_client = segment.create_client(id: "client_#{seq_number + 1}")

# currently there should be only one proejct for the first client
segment.clients.map { |c| [c.id, c.project_uri]}
# => [["client_8", "/gdc/projects/aerkc6562oiauaof9mxtowcc4fl5vwb4"], ["client_9", nil]]

# Let's provision project. This will provision it with project from last call of 'domain.synchronize_clients'
domain.provision_client_projects

# Let's check we have a project
segment.clients.map { |c| [c.id, c.project_uri]}
# => [["client_8", "/gdc/projects/aerkc6562oiauaof9mxtowcc4fl5vwb4"], ["client_9", "/gdc/projects/yxpp45hf39bigezp3ug8pm6kc9h6tihv"]]

# Let's also verify that we have a latest version. The new project should contain the updated version of the dashboard beacuse we already made a release by using 'synchonize_clients' 
segment.clients("client_#{seq_number + 1}").project.dashboards.first.title
# => "Better Test Dashboard"