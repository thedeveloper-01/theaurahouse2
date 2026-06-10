import { IsNotEmpty, IsUUID } from 'class-validator';

export class CreateConversationDto {
  @IsNotEmpty()
  @IsUUID()
  userId: string; // The other user's ID
}
