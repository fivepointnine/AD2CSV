import csv
import names  # You may need to install this package using: pip install names

def generate_username(firstname, lastname):
    return f"{firstname.lower()[0]}{lastname.lower()}"

def generate_users_csv():
    file_path = 'users_1000.csv'
    with open(file_path, 'w', newline='') as csvfile:
        fieldnames = ['username', 'firstname', 'lastname', 'email']
        writer = csv.DictWriter(csvfile, fieldnames=fieldnames)
        writer.writeheader()
        #Change the range for the amount of users you wish to create starting at 0
        for i in range(1, 1001):
            firstname = names.get_first_name()
            lastname = names.get_last_name()
            username = generate_username(firstname, lastname)
            email = f"{firstname.lower()}.{lastname.lower()}@gmail.com"

            writer.writerow({'username': username, 'firstname': firstname, 'lastname': lastname, 'email': email})
            print(f"User {i} created successfully: {username}")

    print(f"\nUser import completed successfully! CSV file saved to: {file_path}")

if __name__ == "__main__":
    generate_users_csv()
