import { IsNotEmpty, IsString, MaxLength } from 'class-validator';

export class CreateMessageDto {
  // conversationId comes from URL parameter, not body - so it's not in this DTO
  @IsNotEmpty()
  @IsString()
  @MaxLength(5000)
  text: string;
}
