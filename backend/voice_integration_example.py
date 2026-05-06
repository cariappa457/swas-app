# Voice Integration Example

This script demonstrates how to integrate a voice module with an existing SOS system and emergency contacts.

## Example Usage

```python
import voice_module  # Assume this is your voice integration module
import sos_system  # Your existing SOS module

class VoiceIntegration:
    def __init__(self, emergency_contacts):
        self.emergency_contacts = emergency_contacts
        self.voice_service = voice_module.VoiceService()  # Initialize voice service

    def listen_for_commands(self):
        command = self.voice_service.listen()  # Use the voice service to listen for a command
        self.process_command(command)

    def process_command(self, command):
        if "emergency" in command.lower():
            self.trigger_sos()
        else:
            print("Command not recognized.")

    def trigger_sos(self):
        for contact in self.emergency_contacts:
            sos_system.send_alert(contact)  # Send SOS alert to each contact
            print(f"SOS alert sent to {contact}")

# Usage
if __name__ == '__main__':
    emergency_contacts = ["contact1@example.com", "contact2@example.com"]
    voice_integration = VoiceIntegration(emergency_contacts)
    voice_integration.listen_for_commands()  # Start listening for voice commands
```